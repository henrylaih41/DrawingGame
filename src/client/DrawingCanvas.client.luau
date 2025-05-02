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
local RunService        = game:GetService("RunService")

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
local SubmitDrawingEvent   = Events:WaitForChild("SubmitDrawing", 10)

local LocalPlayer   = Players.LocalPlayer
local PlayerGui     = LocalPlayer:WaitForChild("PlayerGui")

-- PlayerModule controls reference (for mobile movement / jump UI)
local playerControls  -- will be initialised lazily

------------------------------------------------------------------------
-- 4️⃣  CONFIG / STATE VARS
------------------------------------------------------------------------
local BRUSH_SIZE_MIN, BRUSH_SIZE_MAX = 1, 20

local PENCIL_BRUSH_SIZE  = 5   -- default
local ERASER_BRUSH_SIZE  = 10  -- default

local DRAWING_MODE             = "PENCIL"  -- "PENCIL" | "ERASER"
local CURRENT_COLOR            = Color3.new(0,0,0)
local CANVAS_BACKGROUND_COLOR

local IS_DRAWING       = false
local canvasInitialized= false
local currentGameState = "LOBBY"
local drawingTimeLeft  = 0
local timerRotateScript = nil

-- Track UI event connections for cleanup
local uiConnections = {}

-- History stacks for undo/redo
local undoStack = {}
local redoStack = {}
local MAX_HISTORY = 20  -- Maximum number of states to remember

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
        brushIndicatorPencil.Size = UDim2.fromOffset(PENCIL_BRUSH_SIZE*2, PENCIL_BRUSH_SIZE*2)
    end
    if brushIndicatorEraser then
        brushIndicatorEraser.Size = UDim2.fromOffset(ERASER_BRUSH_SIZE*2, ERASER_BRUSH_SIZE*2)
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
local function updateModeButtonsAppearance(pencilButton, eraserButton)
    -- Reset both buttons
    pencilButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    eraserButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    
    -- Highlight active button
    if DRAWING_MODE == "PENCIL" then
        pencilButton.BackgroundColor3 = Color3.fromRGB(85, 85, 85)
    else -- ERASER
        eraserButton.BackgroundColor3 = Color3.fromRGB(85, 85, 85)
    end
end

local function setupPencilAndEraserButtons(controls: Frame)
    local pencilButton = controls:WaitForChild("PencilButton")
    local eraserButton = controls:WaitForChild("EraserButton")

    -- Setup pencil button
    local connections = {}
    table.insert(connections, pencilButton.MouseButton1Click:Connect(function()
        DRAWING_MODE = "PENCIL"
        updateModeButtonsAppearance(pencilButton, eraserButton)
        refreshIndicatorSizes()
    end))
    
    -- Setup eraser button
    table.insert(connections, eraserButton.MouseButton1Click:Connect(function()
        DRAWING_MODE = "ERASER"
        updateModeButtonsAppearance(pencilButton, eraserButton)
        refreshIndicatorSizes()
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
        updateModeButtonsAppearance(pencilButton, eraserButton)
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

    submitNotification.Visible = true
    
    -- Hide notification after 3 seconds
    task.delay(3, function()
        submitNotification.Visible = false
    end)
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
    -- Disable Roblox mobile move/jump UI
    if not playerControls then
        local pModule = require(LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
        playerControls = pModule:GetControls()
    end

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
    playerControls:Disable()

    CANVAS_BACKGROUND_COLOR = canvasFrame.BackgroundColor3

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
    local sliders = topLevelContainer:WaitForChild("ColorPickerContainer")
    bindBrushSlider(sliders:WaitForChild("BrushSizeSlider"),
        function() return PENCIL_BRUSH_SIZE end,
        function(v) PENCIL_BRUSH_SIZE = v end)

    bindBrushSlider(sliders:WaitForChild("EraserSizeSlider"),
        function() return ERASER_BRUSH_SIZE end,
        function(v) ERASER_BRUSH_SIZE = v end)

    ------------------------------------------------------------------
    -- CONTROL BUTTONS
    ------------------------------------------------------------------
    local controls = topLevelContainer:WaitForChild("Controls")
    setupPencilAndEraserButtons(controls)
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

    UserInputService.InputBegan:Connect(function(i)
        if currentGameState=="DRAWING" and (i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch) then
            local pos = Vector2.new(i.Position.X, i.Position.Y)
            local inset = drawingScreen.IgnoreGuiInset and Vector2.new(0,0) or GuiService:GetGuiInset()
            pos -= Vector2.new(0, inset.Y)
            
            local cPos, cSize = canvasFrame.AbsolutePosition, canvasFrame.AbsoluteSize
            if not (pos.X < cPos.X or pos.X > cPos.X+cSize.X or pos.Y < cPos.Y or pos.Y > cPos.Y+cSize.Y) then
                IS_DRAWING = true
            end
            log("Drawing input began")
            handleDrawing(i)
        end
    end)

    UserInputService.InputChanged:Connect(function(i)
        if IS_DRAWING and 
            (i.UserInputType==Enum.UserInputType.MouseMovement or
             i.UserInputType==Enum.UserInputType.Touch) and
            currentGameState=="DRAWING" then
            handleDrawing(i)
        end
    end)

    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            if IS_DRAWING then
                log("Taking snapshot input ended")
                -- Take snapshot when user finishes drawing
                takeCanvasSnapshot()
            end
            IS_DRAWING = false
            showActiveIndicator(false, Vector2.zero)
            prevX, prevY = nil, nil
        end
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
GameStateChangedEvent.OnClientEvent:Connect(function(stateData)
    local newState = stateData.state
    local theme = stateData.theme
    local prev = currentGameState
    currentGameState = newState

    if newState == "DRAWING" then
        log("Drawing phase started")
        if not canvasInitialized then initCanvas() end
        if timerRotateScript then
            timerRotateScript.start()
        end
        canvasTopBar.Theme.Text = theme
        takeCanvasSnapshot()
        topLevelContainer.Visible = true
        log("Drawing phase enabled")
    else
        if timerRotateScript then
            timerRotateScript.stop()
        end
        log("Drawing Canvas received event:" .. newState)
        if topLevelContainer then topLevelContainer.Visible = false end
        
        if newState == "VOTING" and prev == "DRAWING" then submitDrawing() end

        if prev == "DRAWING" then
            log("Cleaning up drawing phase")
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
            canvasInitialized = false
            cleanupConnections()
            
            -- Re-enable player controls
            if playerControls then
                playerControls:Enable()
            end
            
            -- Clear history stacks
            table.clear(undoStack)
            table.clear(redoStack)
            
            log("Drawing phase cleanup complete")
        end
    end
end)

GameCountdownEvent.OnClientEvent:Connect(function(sec, phase)
    if phase ~= "DRAWING" then return end
    if sec<=0 and currentGameState=="DRAWING" then submitDrawing() end
    if timeLabel then
        local m, s = math.floor(sec / 60), sec % 60
        timeLabel.Text = string.format("%02d:%02d", m,s)
        timeLabel.TextColor3 = (sec<=60) and Color3.fromRGB(255,50,50) or Color3.fromRGB(0,0,0)
    end
end)

initUI()
