--!native
-- DrawingCanvas.client.luau ─ FULL UPDATED VERSION (2025‑04‑21)
-- ▸ Separate brush sizes & indicators for PENCIL / ERASER
-- ▸ Restores **mobile movement & jump UI** after drawing phase
-- ▸ Requires two sliders in UIContainer/ColorPickerContainer:
--       • BrushSizeSlider   (for pencil)
--       • EraserSizeSlider  (for eraser)
-- ▸ Added undo/redo functionality

------------------------------------------------------------------------
-- 1️⃣  SERVICES & MODULES
------------------------------------------------------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local GuiService        = game:GetService("GuiService")

local Color       = require(ReplicatedStorage.Modules.Canvas.ColorPicker)
local DebugUtils  = require(ReplicatedStorage.Modules.Services.DebugUtils)
local InputUtils  = require(ReplicatedStorage.Modules.Utils.InputUtils)
local ButtonEffects = require(ReplicatedStorage.Modules.Utils.ButtonEffects)

------------------------------------------------------------------------
-- 2️⃣  DEBUG LOG WRAPPER
------------------------------------------------------------------------
local DebugFlag = false
local function log(...)
    if DebugFlag then DebugUtils.print("DrawingCanvas:", ...) end
end

------------------------------------------------------------------------
-- 3️⃣  REMOTES & PLAYER REFS
------------------------------------------------------------------------
local Events               = ReplicatedStorage:WaitForChild("Events")
local GameStateChangedEvent= Events:WaitForChild("GameStateChanged")
local GameCountdownEvent   = Events:WaitForChild("GameCountdown")
local SubmitDrawingEvent   = Events:WaitForChild("SubmitDrawing")

local LocalPlayer   = Players.LocalPlayer
local PlayerGui     = LocalPlayer:WaitForChild("PlayerGui")
local GameConstants = require(ReplicatedStorage.Modules.GameData.GameConstants)
local NotificationService = require(ReplicatedStorage.Modules.Utils.NotificationService)

------------------------------------------------------------------------
-- 4️⃣  CONFIG / STATE VARS
------------------------------------------------------------------------
local BRUSH_SIZE_MIN, BRUSH_SIZE_MAX = 1, 20

local PENCIL_BRUSH_SIZE  = 5   -- default
local ERASER_BRUSH_SIZE  = 10  -- default

local DRAWING_MODE             = "PENCIL"  -- "PENCIL" | "ERASER" | "ZOOM"
local CURRENT_COLOR            = Color3.new(0,0,0)
local CANVAS_BACKGROUND_COLOR

local IS_DRAWING       = false
local canvasInitialized= false
local currentGameState = "LOBBY"
local timerRotateScript = nil

-- Track UI event connections for cleanup
local uiConnections = {}

-- History stacks for undo/redo
local undoStack = {}
local redoStack = {}
local MAX_HISTORY = 20  -- Maximum number of states to remember

-- Zoom variables
local ZOOM_LEVEL = 1
local ZOOM_MIN = 0.8
local ZOOM_MAX = 3
local ZOOM_STEP = 0.1
local canvasOriginalSize = nil
local canvasOriginalPosition = nil  -- Add this to store original position
local zoomPinchDistance = nil

-- Canvas drag variables for ZOOM mode
local IS_DRAGGING_CANVAS = false
local canvasDragStartPos = nil
local canvasDragStartMouse = nil
local MAX_DRAG_DISTANCE_SCALE = 1.5  -- Maximum 150% of viewport size the canvas can be dragged from origin

-- Multi-touch tracking
local activeTouches = {}  -- Track active touch inputs

-- Add this near the top with other declarations
local ScreenTransitionEvent = Instance.new("BindableEvent")
_G.ScreenTransitionEvent = ScreenTransitionEvent -- Make it globally accessible

------------------------------------------------------------------------
-- 5️⃣  HELPERS
------------------------------------------------------------------------
local function getActiveBrushSize()
    return (DRAWING_MODE == "PENCIL") and PENCIL_BRUSH_SIZE or ERASER_BRUSH_SIZE
end

------------------------------------------------------------------------
-- 6️⃣  FORWARD DECLS (shared locals across functions)
------------------------------------------------------------------------
local drawingScreen, timeLabel, canvasContainer, canvasFrame, topLevelContainer, canvasTopBar
local brushIndicatorPencil, brushIndicatorEraser
local canvas, cp
local submitNotification
local controlsFrame, colorPickerFrame  -- Add references to UI frames

------------------------------------------------------------------------
-- 7️⃣  INDICATOR HELPERS
------------------------------------------------------------------------
local function makeIndicator(name: string, colour: Color3)
    local f = Instance.new("Frame")
    f.Name                   = name
    f.Size                   = UDim2.fromOffset(getActiveBrushSize()*2, getActiveBrushSize()*2)
    f.BackgroundColor3       = colour
    f.BackgroundTransparency = 1
    f.AnchorPoint            = Vector2.new(0.5,0.5)
    f.Visible                = false
    f.ZIndex                 = 10
    f.Active, f.Selectable   = false,false

    local corner = Instance.new("UICorner", f)
    corner.CornerRadius = UDim.new(0.5,0)

    local stroke = Instance.new("UIStroke", f)
    stroke.Thickness       = 1
    stroke.Color           = Color3.new(0,0,0)
    stroke.LineJoinMode    = Enum.LineJoinMode.Round
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual

    return f
end

local function refreshIndicatorSizes()
    if brushIndicatorPencil then
        brushIndicatorPencil.Size = UDim2.fromOffset(PENCIL_BRUSH_SIZE*2*ZOOM_LEVEL, PENCIL_BRUSH_SIZE*2*ZOOM_LEVEL)
    end
    if brushIndicatorEraser then
        brushIndicatorEraser.Size = UDim2.fromOffset(ERASER_BRUSH_SIZE*2*ZOOM_LEVEL, ERASER_BRUSH_SIZE*2*ZOOM_LEVEL)
    end
end

local function showActiveIndicator(show: boolean, pointerPos: Vector2)
    if not (brushIndicatorPencil and brushIndicatorEraser and canvasFrame) then return end

    brushIndicatorPencil.Visible = false
    brushIndicatorEraser.Visible = false
    if not show then return end

    local ind = (DRAWING_MODE == "PENCIL") and brushIndicatorPencil or brushIndicatorEraser

    local cPos, cSize = canvasFrame.AbsolutePosition, canvasFrame.AbsoluteSize
    if cSize.X == 0 or cSize.Y == 0 then return end

    -- Check if pointer is within canvas bounds
    if pointerPos.X < cPos.X or pointerPos.X > cPos.X+cSize.X or 
       pointerPos.Y < cPos.Y or pointerPos.Y > cPos.Y+cSize.Y then
        return -- Exit function if pointer is outside canvas bounds
    end

    local relX = (pointerPos.X - cPos.X) / cSize.X
    local relY = (pointerPos.Y - cPos.Y) / cSize.Y
    ind.Position = UDim2.fromScale(relX, relY)
    ind.Visible  = true
end

------------------------------------------------------------------------
-- 8️⃣  BRUSH SLIDER BINDING (generic)
------------------------------------------------------------------------
local function bindBrushSlider(slider: Frame, getSize, setSize)
    local track = slider:WaitForChild("Track")
    local knob  = track:WaitForChild("Knob")
    
    -- Helper function to update knob position and size value
    local function updateFromPosition(pos: Vector2)
        local left   = track.AbsolutePosition.X
        local width  = track.AbsoluteSize.X
        local right  = left + width
        local x      = math.clamp(pos.X, left, right)
        local alpha  = (x-left)/width
        knob.Position= UDim2.fromScale(alpha, knob.Position.Y.Scale)
        local sz     = math.floor(BRUSH_SIZE_MIN + alpha*(BRUSH_SIZE_MAX-BRUSH_SIZE_MIN) + 0.5)
        setSize(sz)
        refreshIndicatorSizes()
    end
    
    -- Make track clickable/touchable to jump knob position
    InputUtils.bindDrag(track, function(ptr: Vector2)
        updateFromPosition(ptr)
    end)
    
    -- Keep original knob drag functionality
    InputUtils.bindDrag(knob, function(ptr: Vector2)
        updateFromPosition(ptr)
    end)

    task.defer(function()
        local sz = getSize()
        local alpha = (sz - BRUSH_SIZE_MIN)/(BRUSH_SIZE_MAX-BRUSH_SIZE_MIN)
        knob.Position = UDim2.fromScale(alpha, knob.Position.Y.Scale)
    end)
end

------------------------------------------------------------------------
-- 9️⃣  UI BUTTON SETUP
------------------------------------------------------------------------
local function updateModeButtonsAppearance(pencilButton, eraserButton, magnifyingGlassButton)
    -- Reset all buttons
    pencilButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    eraserButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    magnifyingGlassButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    
    -- Highlight active button
    if DRAWING_MODE == "PENCIL" then
        pencilButton.BackgroundColor3 = Color3.fromRGB(85, 85, 85)
    elseif DRAWING_MODE == "ERASER" then
        eraserButton.BackgroundColor3 = Color3.fromRGB(85, 85, 85)
    else -- ZOOM
        magnifyingGlassButton.BackgroundColor3 = Color3.fromRGB(85, 85, 85)
    end
end

local function applyZoom()
    if not canvasFrame or not canvasOriginalSize then return end
    
    -- Apply zoom by scaling the canvas frame
    local newSize = canvasOriginalSize * ZOOM_LEVEL
    canvasFrame.Size = UDim2.new(0, newSize.X, 0, newSize.Y)
end

local function resetZoom()
    ZOOM_LEVEL = 1
    if canvasFrame and canvasOriginalSize then
        canvasFrame.Size = UDim2.new(0, canvasOriginalSize.X, 0, canvasOriginalSize.Y)
    end
    -- Reset position as well
    if canvasFrame and canvasOriginalPosition then
        canvasFrame.Position = canvasOriginalPosition
    end
end

local function snapCanvasToOrigin()
    if not canvasFrame or not canvasOriginalPosition then return end
    canvasFrame.Position = canvasOriginalPosition
end

local function checkCanvasBounds()
    if not canvasFrame or not canvasOriginalPosition then return false end
    
    local currentPos = canvasFrame.Position
    local originalX = canvasOriginalPosition.X.Offset
    local originalY = canvasOriginalPosition.Y.Offset
    local currentX = currentPos.X.Offset
    local currentY = currentPos.Y.Offset
    
    local distance = math.sqrt((currentX - originalX)^2 + (currentY - originalY)^2)
    
    -- Calculate max distance based on viewport size
    local viewportSize = workspace.CurrentCamera.ViewportSize
    local maxDistance = math.min(viewportSize.X, viewportSize.Y) * MAX_DRAG_DISTANCE_SCALE
    
    return distance <= maxDistance
end

local function setupButtons(controls: Frame)
    local pencilButton = controls:WaitForChild("PencilButton")
    local eraserButton = controls:WaitForChild("EraserButton")
    local magnifyingGlassButton = controls:WaitForChild("MagnifyingGlassButton")

    -- Setup pencil button
    local connections = {}
    table.insert(connections, pencilButton.MouseButton1Click:Connect(function()
        DRAWING_MODE = "PENCIL"
        updateModeButtonsAppearance(pencilButton, eraserButton, magnifyingGlassButton)
        refreshIndicatorSizes()
    end))
    
    -- Setup eraser button
    table.insert(connections, eraserButton.MouseButton1Click:Connect(function()
        DRAWING_MODE = "ERASER"
        updateModeButtonsAppearance(pencilButton, eraserButton, magnifyingGlassButton)
        refreshIndicatorSizes()
    end))
    
    -- Setup magnifying glass button
    table.insert(connections, magnifyingGlassButton.MouseButton1Click:Connect(function()
        DRAWING_MODE = "ZOOM"
        updateModeButtonsAppearance(pencilButton, eraserButton, magnifyingGlassButton)
        -- Hide brush indicators when in zoom mode
        if brushIndicatorPencil then brushIndicatorPencil.Visible = false end
        if brushIndicatorEraser then brushIndicatorEraser.Visible = false end
    end))
    
    -- Add cleanup function
    local cleanup = function()
        for _, connection in ipairs(connections) do
            connection:Disconnect()
        end
    end
    table.insert(uiConnections, cleanup)
    
    -- Set initial button appearance based on default mode
    task.defer(function()
        updateModeButtonsAppearance(pencilButton, eraserButton, magnifyingGlassButton)
    end)
end

local function setupUndoButton(controls: Frame)
    local undoButton = controls:WaitForChild("UndoButton")
    
    local cleanup = ButtonEffects.applyHoverEffects(undoButton, function()
        if #undoStack > 1 and canvas then               -- at least two states
            local current = table.remove(undoStack)     -- pop current
            table.insert(redoStack, current)            -- move → redo
            if #redoStack > MAX_HISTORY then
                table.remove(redoStack, 1)
            end

            canvas:SetBufferFromImage(undoStack[#undoStack]) -- show new top
        end
    end)

    table.insert(uiConnections, cleanup)
end

local function setupRedoButton(controls: Frame)
    local redoButton = controls:WaitForChild("RedoButton")

    local cleanup = ButtonEffects.applyHoverEffects(redoButton, function()
        if #redoStack > 0 and canvas then
            local nextState = table.remove(redoStack)   -- pop redo frame
            table.insert(undoStack, nextState)          -- push → undo
            if #undoStack > MAX_HISTORY then
                table.remove(undoStack, 1)
            end

            canvas:SetBufferFromImage(nextState)     -- show it
        end
    end)

    table.insert(uiConnections, cleanup)
end

local function takeCanvasSnapshot()
    if canvas then
        -- Clear redo stack when new action is taken
        table.clear(redoStack)
        
        log("Taking snapshot")
        -- Add current state to undo stack
        local imageData = canvas:CreateImageDataFromCanvas()
        table.insert(undoStack, imageData)
        
        -- Limit stack size
        if #undoStack > MAX_HISTORY then
            table.remove(undoStack, 1)
        end
    end
end

local function setupClearButton(controls: Frame)
    local clearButton = controls:WaitForChild("ClearButton")
    
    local cleanup = ButtonEffects.applyHoverEffects(clearButton, function()
        if canvas then 
            -- Take snapshot before clearing
            takeCanvasSnapshot()
            canvas:Clear(CANVAS_BACKGROUND_COLOR) 
        end
    end)
    
    table.insert(uiConnections, cleanup)
end

local function submitDrawing()
    if not canvas then return end
    local ok, img = pcall(function() return canvas:CreateImageDataFromCanvas() end)
    if ok and img then 
        SubmitDrawingEvent:FireServer(img) 
    end

    NotificationService:ShowNotification("Great job! Drawing submitted!")
end

local function setupSubmitButton(controls: Frame)
    local submitButton = controls:WaitForChild("SubmitButton")
    
    local cleanup = ButtonEffects.applyHoverEffects(submitButton, function()
        submitDrawing()
    end)
    
    table.insert(uiConnections, cleanup)
end

------------------------------------------------------------------------
-- 🔟  CANVAS INITIALISATION
------------------------------------------------------------------------
-- Note that we want the screenGUI to be enabled before the canvas is initialized
local function initUI() 
    drawingScreen   = PlayerGui:WaitForChild("DrawingScreen")
    topLevelContainer = drawingScreen:WaitForChild("TopLevelContainer")
    canvasContainer = topLevelContainer:WaitForChild("CanvasContainer")
    canvasTopBar    = canvasContainer:WaitForChild("CanvasTopBar")
    timeLabel       = canvasTopBar:WaitForChild("Timer"):WaitForChild("Frame"):WaitForChild("TimeLabel")
    canvasFrame     = canvasContainer:WaitForChild("CanvasFrame")
    submitNotification = topLevelContainer:WaitForChild("SubmitNotification")
    timerRotateScript = _G.TimerRotateScriptModule
end

local function initCanvas()
    if canvasInitialized then return end
    canvasInitialized = true
    -- Hide notification by default
    submitNotification.Visible = false

    CANVAS_BACKGROUND_COLOR = canvasFrame.BackgroundColor3
    
    -- Store original canvas size and position for zoom
    canvasOriginalSize = canvasFrame.AbsoluteSize
    canvasOriginalPosition = canvasFrame.Position  -- Store original position

    local CanvasDraw = require(ReplicatedStorage.Modules.Canvas.CanvasDraw)
    local sz = canvasFrame.AbsoluteSize
    local MAX_CANVAS_DIMENSION = 1024
    
    -- Scale the canvas dimensions if they exceed the maximum allowed size
    local canvasWidth, canvasHeight = math.ceil(sz.X), math.ceil(sz.Y)
    
    log("Canvas width: ", canvasWidth, "Canvas height: ", canvasHeight)
    
    local scaleFactor = 1
    local scaledWidth, scaledHeight = canvasWidth, canvasHeight
    
    -- Use CanvasDraw's scaleCanvasDimensions function to get appropriate dimensions
    scaledWidth, scaledHeight, scaleFactor = CanvasDraw.scaleCanvasDimensions(canvasWidth, canvasHeight)
    
    canvasWidth = scaledWidth
    canvasHeight = scaledHeight

    if scaleFactor < 1 then
        log("Canvas size exceeded maximum dimensions. Scaling by factor:", scaleFactor)
    end
    
    canvas = CanvasDraw.new(canvasFrame, Vector2.new(scaledWidth, scaledHeight))
    log("Canvas ID: ", canvas.Id)
    canvas:Clear(CANVAS_BACKGROUND_COLOR)
    canvas.GridEnabled, canvas.AutoRender = false, true

    brushIndicatorPencil = makeIndicator("BrushIndicatorPencil", CURRENT_COLOR)
    brushIndicatorEraser = makeIndicator("BrushIndicatorEraser", CANVAS_BACKGROUND_COLOR)
    brushIndicatorPencil.Parent = canvasFrame
    brushIndicatorEraser.Parent = canvasFrame

    ------------------------------------------------------------------
    -- COLOR PICKER
    ------------------------------------------------------------------
    cp = Color.New(topLevelContainer)
    cp:SetColor(CURRENT_COLOR)
    cp.Updated:Connect(function(c)
        CURRENT_COLOR = c
        brushIndicatorPencil.BackgroundColor3 = c
    end)

    ------------------------------------------------------------------
    -- SLIDERS
    ------------------------------------------------------------------
    local colorPicker = topLevelContainer:WaitForChild("ColorPickerContainer")
    colorPickerFrame = colorPicker  -- Store reference for input checking
    bindBrushSlider(colorPicker:WaitForChild("BrushSizeSlider"),
        function() return PENCIL_BRUSH_SIZE end,
        function(v) PENCIL_BRUSH_SIZE = v end)

    bindBrushSlider(colorPicker:WaitForChild("EraserSizeSlider"),
        function() return ERASER_BRUSH_SIZE end,
        function(v) ERASER_BRUSH_SIZE = v end)

    ------------------------------------------------------------------
    -- CONTROL BUTTONS
    ------------------------------------------------------------------
    local controls = topLevelContainer:WaitForChild("Controls")
    controlsFrame = controls  -- Store reference for input checking
    setupButtons(controls)
    setupClearButton(controls)
    setupSubmitButton(controls)
    setupUndoButton(controls)
    setupRedoButton(controls)

    ------------------------------------------------------------------
    -- DRAWING LOGIC (same as previous version)
    ------------------------------------------------------------------
    local prevX, prevY
    local function handleDrawing(input: InputObject)
        if not canvas or not topLevelContainer.Visible then return end
        
        -- Don't draw in zoom mode
        if DRAWING_MODE == "ZOOM" then return end

        local pos   = Vector2.new(input.Position.X, input.Position.Y)
        local inset = drawingScreen.IgnoreGuiInset and Vector2.new(0,0) or GuiService:GetGuiInset()
        pos -= Vector2.new(0, inset.Y)

        showActiveIndicator(IS_DRAWING, pos)

        local cPos, cSize = canvasFrame.AbsolutePosition, canvasFrame.AbsoluteSize
        if pos.X < cPos.X or pos.X > cPos.X+cSize.X or pos.Y < cPos.Y or pos.Y > cPos.Y+cSize.Y then
            prevX, prevY = nil, nil
            return end

        local relX = (pos.X - cPos.X)/cSize.X
        local relY = (pos.Y - cPos.Y)/cSize.Y
        
        -- Apply scaling to match the scaled canvas dimensions
        local x = math.round(relX * canvasWidth)
        local y = math.round(relY * canvasHeight)

        local col  = (DRAWING_MODE=="PENCIL") and CURRENT_COLOR or CANVAS_BACKGROUND_COLOR
        local size = getActiveBrushSize()

        if prevX and prevY and IS_DRAWING then
            local dist = ((x-prevX)^2 + (y-prevY)^2)^0.5
            if dist > size*0.5 then
                canvas:DrawLineXY(prevX, prevY, x, y, col, size, true)
            end
        end
        canvas:DrawCircleXY(x, y, size, col, 1, true)
        prevX, prevY = x, y
    end

    -- Store UserInputService connections to manage their lifecycle
    local uisInputBeganConnection
    local uisInputChangedDrawingConnection
    local uisInputEndedConnection
    local uisMouseWheelConnection
    local uisPinchConnection
    local uisTouchStartedConnection
    local uisTouchEndedConnection

    -- Track touch inputs for multi-touch detection
    uisTouchStartedConnection = UserInputService.TouchStarted:Connect(function(touch, gameProcessed)
        activeTouches[touch] = true
        
        -- If multiple touches detected while dragging, cancel the drag
        local touchCount = 0
        for _ in pairs(activeTouches) do
            touchCount = touchCount + 1
        end
        
        if touchCount > 1 and IS_DRAGGING_CANVAS then
            IS_DRAGGING_CANVAS = false
            canvasDragStartPos = nil
            canvasDragStartMouse = nil
            log("Canvas drag cancelled - multiple touches detected")
        end
    end)
    
    uisTouchEndedConnection = UserInputService.TouchEnded:Connect(function(touch, gameProcessed)
        activeTouches[touch] = nil
    end)

    uisInputBeganConnection = UserInputService.InputBegan:Connect(function(i)
        if currentGameState==GameConstants.PlayerStateEnum.DRAWING then
            if DRAWING_MODE ~= "ZOOM" and (i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch) then
                local pos = Vector2.new(i.Position.X, i.Position.Y)
                local inset = drawingScreen.IgnoreGuiInset and Vector2.new(0,0) or GuiService:GetGuiInset()
                pos -= Vector2.new(0, inset.Y)
                
                -- Check if click is on UI controls or color picker
                if controlsFrame and colorPickerFrame then
                    local controlsPos = controlsFrame.AbsolutePosition
                    local controlsSize = controlsFrame.AbsoluteSize
                    local colorPickerPos = colorPickerFrame.AbsolutePosition
                    local colorPickerSize = colorPickerFrame.AbsoluteSize
                    
                    -- Check if click is within Controls frame
                    if pos.X >= controlsPos.X and pos.X <= controlsPos.X + controlsSize.X and
                       pos.Y >= controlsPos.Y and pos.Y <= controlsPos.Y + controlsSize.Y then
                        log("Click on Controls - drawing prevented")
                        return
                    end
                    
                    -- Check if click is within ColorPicker frame
                    if pos.X >= colorPickerPos.X and pos.X <= colorPickerPos.X + colorPickerSize.X and
                       pos.Y >= colorPickerPos.Y and pos.Y <= colorPickerPos.Y + colorPickerSize.Y then
                        log("Click on ColorPicker - drawing prevented")
                        return
                    end
                end
                
                local cPos, cSize = canvasFrame.AbsolutePosition, canvasFrame.AbsoluteSize
                if not (pos.X < cPos.X or pos.X > cPos.X+cSize.X or pos.Y < cPos.Y or pos.Y > cPos.Y+cSize.Y) then
                    IS_DRAWING = true
                end
                log("Drawing input began")
                handleDrawing(i)
            elseif DRAWING_MODE == "ZOOM" and (i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch) then
                -- Only start dragging if it's a single touch (or mouse)
                local touchCount = 0
                for _ in pairs(activeTouches) do
                    touchCount = touchCount + 1
                end
                
                -- For mouse input, always allow. For touch, only allow if single touch
                if i.UserInputType == Enum.UserInputType.MouseButton1 or touchCount <= 1 then
                    -- Start canvas dragging in ZOOM mode
                    IS_DRAGGING_CANVAS = true
                    canvasDragStartPos = canvasFrame.Position
                    canvasDragStartMouse = Vector2.new(i.Position.X, i.Position.Y)
                    log("Canvas drag started")
                else
                    log("Canvas drag prevented - multiple touches detected")
                end
            end
        end
    end)

    uisInputChangedDrawingConnection = UserInputService.InputChanged:Connect(function(i)
        if IS_DRAWING and 
            DRAWING_MODE ~= "ZOOM" and
            (i.UserInputType==Enum.UserInputType.MouseMovement or
             i.UserInputType==Enum.UserInputType.Touch) and
            currentGameState==GameConstants.PlayerStateEnum.DRAWING then
            handleDrawing(i)
        elseif IS_DRAGGING_CANVAS and 
            DRAWING_MODE == "ZOOM" and
            (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) and
            currentGameState==GameConstants.PlayerStateEnum.DRAWING then
            -- Handle canvas dragging
            if canvasDragStartPos and canvasDragStartMouse then
                local currentMouse = Vector2.new(i.Position.X, i.Position.Y)
                local delta = currentMouse - canvasDragStartMouse
                
                -- Update canvas position
                canvasFrame.Position = UDim2.new(
                    canvasDragStartPos.X.Scale,
                    canvasDragStartPos.X.Offset + delta.X,
                    canvasDragStartPos.Y.Scale,
                    canvasDragStartPos.Y.Offset + delta.Y
                )
                
                -- Check if canvas is within bounds
                if not checkCanvasBounds() then
                    -- Snap back if too far
                    snapCanvasToOrigin()
                    IS_DRAGGING_CANVAS = false
                    canvasDragStartPos = nil
                    canvasDragStartMouse = nil
                    log("Canvas snapped back to origin - exceeded bounds")
                end
            end
        end
    end)

    uisInputEndedConnection = UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            if IS_DRAWING then
                log("Taking snapshot input ended")
                -- Take snapshot when user finishes drawing
                takeCanvasSnapshot()
            elseif IS_DRAGGING_CANVAS then
                IS_DRAGGING_CANVAS = false
                canvasDragStartPos = nil
                canvasDragStartMouse = nil
                log("Canvas drag ended")
            end
            IS_DRAWING = false
            showActiveIndicator(false, Vector2.zero)
            prevX, prevY = nil, nil
        end
    end)
    
    -- Mouse wheel zoom for PC
    uisMouseWheelConnection = UserInputService.InputChanged:Connect(function(input)
        if DRAWING_MODE == "ZOOM" and input.UserInputType == Enum.UserInputType.MouseWheel then
            local delta = input.Position.Z
            ZOOM_LEVEL = math.clamp(ZOOM_LEVEL + (delta * ZOOM_STEP), ZOOM_MIN, ZOOM_MAX)
            applyZoom()
        end
    end)
    
    -- Pinch zoom for mobile
    uisPinchConnection = UserInputService.TouchPinch:Connect(function(touchPositions, scale, velocity, state)
        if DRAWING_MODE == "ZOOM" and currentGameState == GameConstants.PlayerStateEnum.DRAWING then
            if state == Enum.UserInputState.Begin then
                zoomPinchDistance = scale
            elseif state == Enum.UserInputState.Change then
                if zoomPinchDistance then
                    local scaleDelta = scale / zoomPinchDistance
                    ZOOM_LEVEL = math.clamp(ZOOM_LEVEL * scaleDelta, ZOOM_MIN, ZOOM_MAX)
                    applyZoom()
                    zoomPinchDistance = scale
                end
            elseif state == Enum.UserInputState.End then
                zoomPinchDistance = nil
            end
        end
    end)

    -- Add a cleanup function for these UserInputService connections
    table.insert(uiConnections, function()
        if uisInputBeganConnection then
            uisInputBeganConnection:Disconnect()
            uisInputBeganConnection = nil
        end
        if uisInputChangedDrawingConnection then
            uisInputChangedDrawingConnection:Disconnect()
            uisInputChangedDrawingConnection = nil
        end
        if uisInputEndedConnection then
            uisInputEndedConnection:Disconnect()
            uisInputEndedConnection = nil
        end
        if uisMouseWheelConnection then
            uisMouseWheelConnection:Disconnect()
            uisMouseWheelConnection = nil
        end
        if uisPinchConnection then
            uisPinchConnection:Disconnect()
            uisPinchConnection = nil
        end
        if uisTouchStartedConnection then
            uisTouchStartedConnection:Disconnect()
            uisTouchStartedConnection = nil
        end
        if uisTouchEndedConnection then
            uisTouchEndedConnection:Disconnect()
            uisTouchEndedConnection = nil
        end
        log("Cleaned up UserInputService connections for drawing canvas")
    end)
end

local function cleanupConnections()
    for _, cleanup in ipairs(uiConnections) do
        cleanup()
    end
    table.clear(uiConnections)
end
------------------------------------------------------------------------
-- 1️⃣1️⃣  GAME STATE & COUNTDOWN HANDLERS
------------------------------------------------------------------------
initUI()

GameStateChangedEvent.OnClientEvent:Connect(function(stateData)
    local newState = stateData.state
    local prev = currentGameState
    currentGameState = newState

    if newState == GameConstants.PlayerStateEnum.DRAWING then
        local themeTitle = stateData.themeName.. " [" .. stateData.themeDifficulty .. "]"
        log("Drawing phase started")
        if not canvasInitialized then initCanvas() end
        if timerRotateScript then
            timerRotateScript.start()
        end
        canvasTopBar.Theme.Text = themeTitle
        canvasTopBar.Theme.AutoLocalize = true
        takeCanvasSnapshot()
        topLevelContainer.Visible = true
        log("Drawing phase enabled")
    else
        log("Drawing Canvas received event:" .. newState)
        topLevelContainer.Visible = false
        if prev == GameConstants.PlayerStateEnum.DRAWING then
            log("Cleaning up drawing phase")

            if timerRotateScript then
                timerRotateScript.stop()
            end

            -- Clean up when leaving drawing phase
            if canvas then
                log("Destroying canvas " .. canvas.Id)
                canvas:Destroy()
                canvas = nil
            end
            
            -- Clean up brush indicators
            if brushIndicatorPencil then
                brushIndicatorPencil:Destroy()
                brushIndicatorPencil = nil
            end
            
            if brushIndicatorEraser then
                brushIndicatorEraser:Destroy()
                brushIndicatorEraser = nil
            end

            if cp then
                cp:Destroy()
                cp = nil
            end
            
            -- Reset state variables
            IS_DRAWING = false
            IS_DRAGGING_CANVAS = false
            canvasDragStartPos = nil
            canvasDragStartMouse = nil
            canvasInitialized = false
            controlsFrame = nil  -- Clear UI frame references
            colorPickerFrame = nil
            table.clear(activeTouches)  -- Clear active touches
            cleanupConnections()
            
            -- Clear history stacks
            table.clear(undoStack)
            table.clear(redoStack)
            
            -- Reset zoom
            resetZoom()
            
            log("Drawing phase cleanup complete")
        end
    end
end)

GameCountdownEvent.OnClientEvent:Connect(function(sec, phase)
    if phase ~= GameConstants.PlayerStateEnum.DRAWING then return end
    if sec<=0 and currentGameState==GameConstants.PlayerStateEnum.DRAWING then submitDrawing() end
    if timeLabel then
        local m, s = math.floor(sec / 60), sec % 60
        timeLabel.Text = string.format("%02d:%02d", m,s)
        timeLabel.TextColor3 = (sec<=60) and Color3.fromRGB(255,50,50) or Color3.fromRGB(0,0,0)
    end
end)