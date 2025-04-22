--!native
-- DrawingCanvas.client.luau ─ FULL UPDATED VERSION (2025‑04‑21)
-- ▸ Separate brush sizes & indicators for PENCIL / ERASER
-- ▸ Restores **mobile movement & jump UI** after drawing phase
-- ▸ Requires two sliders in UIContainer/ColorPickerContainer:
--       • BrushSizeSlider   (for pencil)
--       • EraserSizeSlider  (for eraser)

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

------------------------------------------------------------------------
-- 2️⃣  DEBUG LOG WRAPPER
------------------------------------------------------------------------
local DebugFlag = true
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

------------------------------------------------------------------------
-- 5️⃣  HELPERS
------------------------------------------------------------------------
local function getActiveBrushSize()
    return (DRAWING_MODE == "PENCIL") and PENCIL_BRUSH_SIZE or ERASER_BRUSH_SIZE
end

------------------------------------------------------------------------
-- 6️⃣  FORWARD DECLS (shared locals across functions)
------------------------------------------------------------------------
local drawingScreen, timeLabel, canvasContainer, uiContainer, canvasFrame
local brushIndicatorPencil, brushIndicatorEraser
local canvas

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

    InputUtils.bindDrag(knob, function(ptr: Vector2)
        local left   = track.AbsolutePosition.X
        local width  = track.AbsoluteSize.X
        local right  = left + width
        local x      = math.clamp(ptr.X, left, right)
        local alpha  = (x-left)/width
        knob.Position= UDim2.fromScale(alpha, knob.Position.Y.Scale)
        local sz     = math.floor(BRUSH_SIZE_MIN + alpha*(BRUSH_SIZE_MAX-BRUSH_SIZE_MIN) + 0.5)
        setSize(sz)
        refreshIndicatorSizes()
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
local function setupPencilAndEraserButtons(controls: Frame)
    local pencilButton = controls:WaitForChild("PencilButton")
    local eraserButton = controls:WaitForChild("EraserButton")

    pencilButton.MouseButton1Click:Connect(function()
        DRAWING_MODE = "PENCIL"
        refreshIndicatorSizes()
    end)

    eraserButton.MouseButton1Click:Connect(function()
        DRAWING_MODE = "ERASER"
        refreshIndicatorSizes()
    end)
end

local function setupClearButton(controls: Frame)
    local clearButton = controls:WaitForChild("ClearButton")
    clearButton.MouseButton1Click:Connect(function()
        if canvas then canvas:Clear(CANVAS_BACKGROUND_COLOR) end
    end)
end

local function submitDrawing()
    if not canvas then return end
    local ok, img = pcall(function() return canvas:CreateImageDataFromCanvas() end)
    if ok and img then SubmitDrawingEvent:FireServer(img) end
end

local function setupSubmitButton(controls: Frame)
    controls:WaitForChild("SubmitButton").MouseButton1Click:Connect(submitDrawing)
end

------------------------------------------------------------------------
-- 🔟  CANVAS INITIALISATION
------------------------------------------------------------------------
local function initCanvas()
    if canvasInitialized then return end
    canvasInitialized = true

    -- Disable Roblox mobile move/jump UI
    if not playerControls then
        local pModule = require(LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
        playerControls = pModule:GetControls()
    end
    playerControls:Disable()

    drawingScreen   = PlayerGui:WaitForChild("DrawingScreen")
    timeLabel       = drawingScreen:WaitForChild("TimeLabel")
    canvasContainer = drawingScreen:WaitForChild("CanvasContainer")
    uiContainer     = drawingScreen:WaitForChild("UIContainer")
    canvasFrame     = canvasContainer:WaitForChild("CanvasFrame")

    CANVAS_BACKGROUND_COLOR = canvasFrame.BackgroundColor3

    local CanvasDraw = require(ReplicatedStorage.Modules.Canvas.CanvasDraw)
    local sz         = canvasFrame.AbsoluteSize
    canvas = CanvasDraw.new(canvasFrame, Vector2.new(math.ceil(sz.X), math.ceil(sz.Y)))
    canvas:Clear(CANVAS_BACKGROUND_COLOR)
    canvas.GridEnabled, canvas.AutoRender = false, true

    brushIndicatorPencil = makeIndicator("BrushIndicatorPencil", CURRENT_COLOR)
    brushIndicatorEraser = makeIndicator("BrushIndicatorEraser", CANVAS_BACKGROUND_COLOR)
    brushIndicatorPencil.Parent = canvasFrame
    brushIndicatorEraser.Parent = canvasFrame

    ------------------------------------------------------------------
    -- COLOR PICKER
    ------------------------------------------------------------------
    local cp = Color.New(uiContainer)
    cp:SetColor(CURRENT_COLOR)
    cp.Updated:Connect(function(c)
        CURRENT_COLOR = c
        brushIndicatorPencil.BackgroundColor3 = c
    end)

    ------------------------------------------------------------------
    -- SLIDERS
    ------------------------------------------------------------------
    local sliders = uiContainer:WaitForChild("ColorPickerContainer")
    bindBrushSlider(sliders:WaitForChild("BrushSizeSlider"),
        function() return PENCIL_BRUSH_SIZE end,
        function(v) PENCIL_BRUSH_SIZE = v end)

    bindBrushSlider(sliders:WaitForChild("EraserSizeSlider"),
        function() return ERASER_BRUSH_SIZE end,
        function(v) ERASER_BRUSH_SIZE = v end)

    ------------------------------------------------------------------
    -- CONTROL BUTTONS
    ------------------------------------------------------------------
    local controls = uiContainer:WaitForChild("Controls")
    setupPencilAndEraserButtons(controls)
    setupClearButton(controls)
    setupSubmitButton(controls)

    ------------------------------------------------------------------
    -- DRAWING LOGIC (same as previous version)
    ------------------------------------------------------------------
    local prevX, prevY
    local function handleDrawing(input: InputObject)
        if not canvas or not drawingScreen.Enabled then return end

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
        local x, y = math.round(relX*cSize.X), math.round(relY*cSize.Y)

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
            IS_DRAWING = true
            handleDrawing(i)
        end
    end)

    UserInputService.InputChanged:Connect(function(i)
        if IS_DRAWING and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) and currentGameState=="DRAWING" then
            handleDrawing(i)
        end
    end)

    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            IS_DRAWING = false
            showActiveIndicator(false, Vector2.zero)
            prevX, prevY = nil, nil
        end
    end)

    refreshIndicatorSizes()
end

------------------------------------------------------------------------
-- 1️⃣1️⃣  GAME STATE & COUNTDOWN HANDLERS
------------------------------------------------------------------------
GameStateChangedEvent.OnClientEvent:Connect(function(newState)
    local prev = currentGameState
    currentGameState = newState

    if newState == "DRAWING" then
        if not canvasInitialized then initCanvas() end
        drawingScreen.Enabled = true
    else
        if drawingScreen then drawingScreen.Enabled = false end
        if newState == "VOTING" and prev == "DRAWING" then submitDrawing() end
        if newState == "LOBBY" and canvas then canvas:Clear(CANVAS_BACKGROUND_COLOR) end

        -- Re‑enable mobile controls when leaving drawing phase
        if playerControls then playerControls:Enable() end
    end
end)

GameCountdownEvent.OnClientEvent:Connect(function(sec, phase)
    if phase ~= "DRAWING" then return end
    drawingTimeLeft = sec
    if sec<=0 and currentGameState=="DRAWING" then submitDrawing() end
    if timeLabel then
        local m, s = math.floor(sec/60), sec%60
        timeLabel.Text = string.format("Time Remaining: %d:%02d", m,s)
        timeLabel.TextColor3 = (sec<=30) and Color3.fromRGB(255,50,50) or Color3.fromRGB(0,0,0)
    end
end)
