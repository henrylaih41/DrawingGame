--!native
-- DrawingCanvas.client.luau
-- Interactive drawing canvas implementation using the CanvasDraw module
-- Integrated with game state management

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Color = require(ReplicatedStorage.Modules.Canvas.ColorPicker)
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local DebugFlag = true
local DebugUtils = require(ReplicatedStorage.Modules.Services.DebugUtils) -- Added: Import DebugUtils
local RunService = game:GetService("RunService") -- Added RunService
local GuiService = game:GetService("GuiService") -- Added GuiService

-- Debug logging function using DebugUtils
--- Logs a message to the console if DebugFlag is enabled.
--- @param ... any The message parts to log.
local function log(...) -- Renamed and updated function signature
    if DebugFlag then
        DebugUtils.print("DrawingCanvas:", ...) -- Updated: Use DebugUtils.print
    end
end

log("Script started") -- Updated: Use new log function

-- Get the CanvasDraw module
local CanvasDraw = nil
local success, error = pcall(function()
    CanvasDraw = require(ReplicatedStorage.Modules.Canvas.CanvasDraw)
    log("CanvasDraw module loaded successfully") -- Updated: Use new log function
end)

if not success then
    warn("FAILED TO LOAD CANVASDRAW MODULE: ", error)
    return -- Exit if we can't load the module
end

-- Get Remote Events
local Events = ReplicatedStorage:WaitForChild("Events")
local GameStateChangedEvent = Events:WaitForChild("GameStateChanged")
local GameCountdownEvent = Events:WaitForChild("GameCountdown")
local SubmitDrawingEvent = Events:WaitForChild("SubmitDrawing", 10)

local LocalPlayer = Players.LocalPlayer
log("LocalPlayer reference acquired:", tostring(LocalPlayer)) -- Updated: Use new log function
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
log("PlayerGui reference acquired") -- Updated: Use new log function

-- Configuration
local CANVAS_BACKGROUND_COLOR = nil 
local DEFAULT_COLOR = Color3.new(0, 0, 0) -- Black
local CURRENT_COLOR = DEFAULT_COLOR
local DRAWING_COLOR = CURRENT_COLOR
local BRUSH_SIZE = 5
local IS_DRAWING = false
local DRAWING_MODE = "PENCIL"
local canvas = nil -- Canvas object reference
local drawingScreen = nil -- Reference to the DrawingScreen UI
local timeLabel = nil -- Reference to the TimeLabel UI
local topLevelFrame = nil -- Reference to the TopLevelFrame UI
local currentGameState = "LOBBY"
local drawingTimeLeft = 0
local canvasInitialized = false -- Flag to track canvas initialization
local canvasFrame = nil -- Declare canvasFrame at a higher scope
local brushIndicator = nil -- Declare brushIndicator at a higher scope

local createBrushIndicator = function()
    if brushIndicator then brushIndicator:Destroy() end -- Destroy previous if any
    brushIndicator = Instance.new("Frame")
    brushIndicator.Name = "BrushIndicator"
    brushIndicator.Size = UDim2.fromOffset(BRUSH_SIZE * 1.8, BRUSH_SIZE * 1.8) -- Initial size based on default
    brushIndicator.BackgroundColor3 = CURRENT_COLOR -- Initial color
    brushIndicator.BackgroundTransparency = 1.0 -- Semi-transparent
    brushIndicator.AnchorPoint = Vector2.new(0.5, 0.5) -- Center the frame on the position
    brushIndicator.Visible = false -- Initially hidden
    brushIndicator.ZIndex = 10 -- Ensure it's above the canvas, adjust if needed
    brushIndicator.Active = false -- Prevent input capture
    brushIndicator.Selectable = false -- Prevent selection
    brushIndicator.Parent = canvasFrame-- Parent to the main screen

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.5, 0) -- Makes it a circle
    corner.Parent = brushIndicator

    -- Add UIStroke for the border/outline
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1 -- Border thickness
    stroke.Color = Color3.fromRGB(0, 0, 0) -- Border color (black)
    stroke.Transparency = 0.5 -- Border transparency
    stroke.LineJoinMode = Enum.LineJoinMode.Round -- Smoother joins for the circle
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual -- Apply stroke inside the bounds
    stroke.Parent = brushIndicator

    log("Brush indicator created with UICorner and UIStroke") -- Updated log message
end

local function updateBrushIndicator(pointerPos)
    -- If brushIndicator is not found, return
    if not brushIndicator then
        return
    end

    if not IS_DRAWING then
        brushIndicator.Visible = false
        return
    end

    local canvasPosition = canvasFrame.AbsolutePosition
    local canvasSize = canvasFrame.AbsoluteSize

    -- Check if pointer is inside the canvas frame bounds using the adjusted Y position
    if pointerPos.X >= canvasPosition.X and
       pointerPos.X <= canvasPosition.X + canvasSize.X and
       pointerPos.Y >= canvasPosition.Y and -- Use adjusted Y
       pointerPos.Y <= canvasPosition.Y + canvasSize.Y then -- Use adjusted Y

        -- Pointer is inside: show and position the indicator
        if not brushIndicator.Visible then -- Only update if needed
             brushIndicator.Visible = true
        end
        -- Calculate position relative to the canvasFrame (parent) size
        if canvasSize.X > 0 and canvasSize.Y > 0 then
            local relativePointerX = pointerPos.X - canvasPosition.X
            local relativePointerY = pointerPos.Y - canvasPosition.Y -- Use adjusted Y
            local scaleX = relativePointerX / canvasSize.X
            local scaleY = relativePointerY / canvasSize.Y
            brushIndicator.Position = UDim2.fromScale(scaleX, scaleY)
        else
            if brushIndicator.Visible then -- Only update if needed
                brushIndicator.Visible = false
            end
            warn("Warning: canvasFrame AbsoluteSize is zero, cannot position brush indicator.")
        end
    else
        -- Pointer is outside: hide the indicator
        if brushIndicator.Visible then -- Only update if needed
            brushIndicator.Visible = false
        end
    end
end

local function showNotification(message, duration)
    assert(duration, "Duration is required")
    
    if drawingScreen and drawingScreen:FindFirstChild("Notification") then
        local notification = drawingScreen.Notification
        notification.Text = message
        notification.Visible = true
        
        task.delay(duration, function()
            notification.Visible = false
        end)
    end
end

-- Function to submit drawing
local function submitDrawing()
    if not canvas then
        showNotification("Error: Canvas not available", 3)
        return
    end
    
    -- Create image data from canvas
    local success, imageData = pcall(function()
        return canvas:CreateImageDataFromCanvas()
    end)
    
    if success and imageData then
        log("Drawing saved successfully, submitting to server") -- Updated: Use new log function
        
        -- Submit to server
        SubmitDrawingEvent:FireServer(imageData)
        
        -- Show confirmation
        showNotification("Drawing submitted successfully!", 3)
    else
        warn("Failed to save drawing: ", imageData)
        showNotification("Failed to submit drawing", 3)
    end
end

-- Function to check if canvas UI is enabled/visible
local function isCanvasEnabled()
    if not drawingScreen then
        return false
    end
    
    -- Check if the ScreenGui is enabled
    if drawingScreen:IsA("ScreenGui") then
        return drawingScreen.Enabled
    else 
        assert(false, "DrawingScreen is not a ScreenGui")
    end
end

local function setupPencilAndEraserButtons(controls)
    local pencilButton = controls:WaitForChild("PencilButton")
    local eraserButton = controls:WaitForChild("EraserButton")

    pencilButton.MouseButton1Click:Connect(function()
        log("Pencil button clicked") -- Updated: Use new log function
        DRAWING_MODE = "PENCIL"
    end)

    eraserButton.MouseButton1Click:Connect(function()
        log("Eraser button clicked") -- Updated: Use new log function
        DRAWING_MODE = "ERASER"
    end)
end

local function setupClearButton(controls)
        -- Clear button functionality
    local clearButton = controls:WaitForChild("ClearButton")
    log("ClearButton found") -- Updated: Use new log function
    
    clearButton.MouseButton1Click:Connect(function()
        log("Clear button clicked") -- Updated: Use new log function
        if canvas then
            canvas:Clear(Color3.new(1, 1, 1)) -- Clear to white
            log("Canvas cleared") -- Updated: Use new log function
        else
            warn("Cannot clear canvas - canvas object is nil")
        end
    end)
end

local function setupSubmitButton(controls)
    -- Submit button functionality 
    local submitButton = controls:WaitForChild("SubmitButton")
    log("SubmitButton found") -- Updated: Use new log function
    
    submitButton.MouseButton1Click:Connect(function()
        log("Submit button clicked") -- Updated: Use new log function
        submitDrawing()
    end)
end
    
-- Function to update brush size based on slider position
local function updateBrushSize(sizeSlider, sizeValue, inputPosition)
    local sliderPosition = sizeSlider.AbsolutePosition
    local sliderSize = sizeSlider.AbsoluteSize
    -- Use provided input position (for touch/click) or fallback to current mouse location
    local currentPosition = inputPosition or UserInputService:GetMouseLocation()
    currentPosition = currentPosition - Vector2.new(0, GuiService:GetGuiInset().Y)

    -- Calculate relative position (0-1)
    local relativeX = math.clamp((currentPosition.X - sliderPosition.X) / sliderSize.X, 0, 1)

    -- Convert to brush size (1-20)
    BRUSH_SIZE = math.floor(1 + relativeX * 19)
    sizeValue.Text = tostring(BRUSH_SIZE)
    log("Brush size updated to:", BRUSH_SIZE) -- Updated: Use new log function

    -- Update brush indicator size
    if brushIndicator then
        brushIndicator.Size = UDim2.fromOffset(BRUSH_SIZE * 2, BRUSH_SIZE * 2)
    end
end

-- Function to initialize the canvas
local function initCanvas()
    -- Prevent multiple initializations
    if canvasInitialized then
        log("Canvas already initialized, skipping initialization") -- Updated: Use new log function
        return
    end
    
    local playerMod = require(LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
    local playerControls = playerMod:GetControls()
    playerControls:Disable()      -- joystick + jump vanish, camera still works
    log("initCanvas function started") -- Updated: Use new log function
    -- Set initialization flag to true
    canvasInitialized = true
    drawingScreen = PlayerGui:WaitForChild("DrawingScreen")
    timeLabel = drawingScreen:WaitForChild("TimeLabel")
    topLevelFrame = drawingScreen:WaitForChild("TopLevelFrame")
    -- Get UI references
    canvasFrame = topLevelFrame:WaitForChild("CanvasFrame") -- Assign to higher scope variable

    CANVAS_BACKGROUND_COLOR = canvasFrame.BackgroundColor3
    assert(canvasFrame, "Canvas not found in DrawingScreen")
    local controls = topLevelFrame:WaitForChild("Controls")
    assert(controls, "Controls not found in DrawingScreen")
    
    -- Create canvas with CanvasDraw
    if canvas then
        canvas:Destroy()
    end
    
    -- Use the actual frame size instead of a fixed resolution
    local frameSize = canvasFrame.AbsoluteSize
    log("Frame size:", frameSize.X, ",", frameSize.Y) -- Updated: Use new log function
    canvas = CanvasDraw.new(canvasFrame, Vector2.new(math.ceil(frameSize.X), math.ceil(frameSize.Y)))
    canvas:Clear(CANVAS_BACKGROUND_COLOR) -- Start with white background
    canvas.GridEnabled = false  -- Disable grid
    canvas.AutoRender = true    -- Enable auto rendering
    
    createBrushIndicator()

    -- Add variable to track previous drawing position
    local prevCanvasX = nil
    local prevCanvasY = nil

    -- Set up color picker
    local c = Color.New(topLevelFrame)
    c:SetColor(CURRENT_COLOR)
    
    c.Updated:Connect(function(color)
        CURRENT_COLOR = color
        -- Update brush indicator color
        if brushIndicator then
            brushIndicator.BackgroundColor3 = color
        end
        log("Color updated via picker:", color)
    end)
    
    setupPencilAndEraserButtons(controls)
    setupClearButton(controls)
    setupSubmitButton(controls)
    
    -- Brush size slider functionality
    local sizeSlider = controls:WaitForChild("SizeSlider")
    assert(sizeSlider, "SizeSlider not found")
    
    local sizeValue = controls:WaitForChild("SizeValue")
    assert(sizeValue, "SizeValue not found")
    
    -- Use UserInputService to handle slider interaction
    local isDraggingSlider = false
    
    -- Connect slider input handlers
    sizeSlider.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDraggingSlider = true
            -- Pass the specific input position for accuracy
            updateBrushSize(sizeSlider, sizeValue, Vector2.new(input.Position.X, input.Position.Y))
        end
    end)
    
    sizeSlider.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDraggingSlider = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if isDraggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            -- Pass the specific input position for accuracy during drag
            updateBrushSize(sizeSlider, sizeValue, Vector2.new(input.Position.X, input.Position.Y))
        end
    end)

    -- Drawing functionality
    local function handleDrawing(input)
        if not isCanvasEnabled() or not canvas then return end

        -- Check for relevant input types
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and
           input.UserInputType ~= Enum.UserInputType.MouseMovement and
           input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        -- Get the absolute position and size of the canvas frame
        local canvasPosition = canvasFrame.AbsolutePosition
        local canvasSize = canvasFrame.AbsoluteSize

        -- Get the input position, adjusting for GuiInset
        local currentPos = Vector2.new(input.Position.X, input.Position.Y) -- Use input.Position for Touch and initial MouseButton1/Touch
        log(input.Position)
        log(UserInputService:GetMouseLocation())

        -- if input.UserInputType == Enum.UserInputType.MouseMovement then
        --      -- For mouse movement, GetMouseLocation is more reliable during drag
        --     currentPos = UserInputService:GetMouseLocation()
        -- end

        local inset = GuiService:GetGuiInset()
        if (drawingScreen.IgnoreGuiInset) then
            inset = Vector2.new(0, 0)
        end

        currentPos = currentPos - Vector2.new(0, inset.Y)

        updateBrushIndicator(currentPos)

        log("Input position:", currentPos.X, ",", currentPos.Y, "| Canvas position:", -- Updated: Use new log function
                  canvasPosition.X, ",", canvasPosition.Y, "| Canvas size:",
                  canvasSize.X, ",", canvasSize.Y)

        -- Check if input is inside the canvas
        if currentPos.X >= canvasPosition.X and
           currentPos.X <= canvasPosition.X + canvasSize.X and
           currentPos.Y >= canvasPosition.Y and
           currentPos.Y <= canvasPosition.Y + canvasSize.Y then

            log("Input is inside canvas boundaries") -- Updated: Use new log function


            -- Calculate relative position within the canvas (0-1)
            local relX = (currentPos.X - canvasPosition.X) / canvasSize.X
            local relY = (currentPos.Y - canvasPosition.Y) / canvasSize.Y

            -- Convert to canvas pixel coordinates - use math.round for more precise positioning
            local canvasX = math.round(relX * canvasSize.X)
            local canvasY = math.round(relY * canvasSize.Y)

            if DRAWING_MODE == "PENCIL" then
                DRAWING_COLOR = CURRENT_COLOR -- Update drawing color
            elseif DRAWING_MODE == "ERASER" then
                DRAWING_COLOR = CANVAS_BACKGROUND_COLOR -- Update drawing color
            end

            log("Drawing at canvas position:", canvasX, ",", canvasY, -- Updated: Use new log function
                     "| Relative position:", relX, ",", relY,
                     "| Using brush size:", BRUSH_SIZE,
                     "| Using color:", tostring(DRAWING_COLOR))

            -- Draw a circle at the input position
            if canvas then
                -- If we have a previous position and we're in the middle of drawing,
                -- draw a line to connect the dots
                if prevCanvasX and prevCanvasY and IS_DRAWING then
                    -- Calculate distance between points
                    local distance = math.sqrt((canvasX - prevCanvasX)^2 + (canvasY - prevCanvasY)^2)

                    -- Only draw a line if points are far enough apart (prevents duplicate circles)
                    -- Adjust threshold based on input type? Maybe not necessary yet.
                    if distance > BRUSH_SIZE * 0.5 then
                        -- Draw line between previous point and current point for smoothing
                        canvas:DrawLineXY(prevCanvasX, prevCanvasY, canvasX, canvasY, DRAWING_COLOR, BRUSH_SIZE, true)
                    end
                end

                -- Always draw a circle at the current position for consistent brush appearance
                canvas:DrawCircleXY(canvasX, canvasY, BRUSH_SIZE, DRAWING_COLOR, 1, true)

                -- Update previous position for next drawing operation
                prevCanvasX = canvasX
                prevCanvasY = canvasY
            else
                warn("Cannot draw - canvas object is nil")
            end
        else
            log("Input position outside canvas boundaries") -- Updated: Use new log function
            -- Reset previous position if finger/mouse drags off canvas
            prevCanvasX = nil
            prevCanvasY = nil
        end
    end

    -- Connect drawing input handlers
    UserInputService.InputBegan:Connect(function(input)
        log("InputBegan event received:", input.UserInputType) -- Updated: Use new log function
        -- Handle both MouseButton1 and Touch starts
        if currentGameState == "DRAWING" and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            IS_DRAWING = true
            brushIndicator.Visible = true -- Show indicator immediately on touch/click
            handleDrawing(input)
        end
    end)

    -- Mouse/Touch button up - stop drawing and reset previous position
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if IS_DRAWING then
                 log("InputEnded event received for drawing:", input.UserInputType)
                 IS_DRAWING = false
                 brushIndicator.Visible = false -- Hide indicator when drawing stops
                 -- Reset previous position when we stop drawing
                 prevCanvasX = nil
                 prevCanvasY = nil
            end
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        -- Handle both MouseMovement and Touch movement while drawing
        if IS_DRAWING and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and currentGameState == "DRAWING" then
            log("InputChanged event received while drawing:", input.UserInputType) -- Updated: Use new log function
            handleDrawing(input)
        end
        -- Handle slider dragging (already covered by the slider-specific InputChanged connection)
    end)

    log("Canvas initialization complete") -- Updated: Use new log function
end

-- Function to update the drawing time display
local function updateTimeDisplay()
    if timeLabel then
        local minutes = math.floor(drawingTimeLeft / 60)
        local seconds = drawingTimeLeft % 60
        timeLabel.Text = string.format("Time Remaining: %d:%02d", minutes, seconds)
        
        -- Make time red when less than 30 seconds
        if drawingTimeLeft <= 30 then
            timeLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
        else
            timeLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
        end
    end
end

-- Handle game state changes
GameStateChangedEvent.OnClientEvent:Connect(function(newState)
    log("Game state changed from:", currentGameState, "to:", newState) -- Updated: Use new log function
    local previousGameState = currentGameState -- Store the previous state
    currentGameState = newState -- Update to the new state

    if newState == "DRAWING" then
        -- Initialize canvas if not already done
        if not canvasInitialized then
            initCanvas()
        end

        -- Show drawing UI
        if drawingScreen then
            drawingScreen.Enabled = true
            showNotification("Start drawing now!", 3)
        else
            -- Assert false if drawingScreen is not available when needed
            assert(false, "DrawingScreen is nil when trying to enable it for DRAWING state")
        end
    else
        -- Hide drawing UI for other states
        if drawingScreen then
            drawingScreen.Enabled = false
        else
            -- It might be okay for drawingScreen to be nil here if the UI isn't meant to be shown,
            -- but add a debug log for clarity or assert if it should exist.
            log("DrawingScreen is nil while hiding UI for state:", newState) -- Updated: Use new log function
        end

        -- If leaving drawing phase and canvas exists, attempt to submit
        -- Use previousGameState to check if we were just drawing
        if newState == "VOTING" and canvas and previousGameState == "DRAWING" then
            log("Transitioning from DRAWING to VOTING, submitting drawing.") -- Updated: Use new log function
            submitDrawing()
        end
    end

    -- Reset canvas if returning to lobby
    if newState == "LOBBY" then
        if canvas then
            canvas:Clear(Color3.new(1, 1, 1))
            log("Canvas cleared on returning to LOBBY") -- Updated: Use new log function
        else
            -- Log if canvas is nil when trying to clear, might indicate an issue
            log("Canvas is nil when trying to clear for LOBBY state") -- Updated: Use new log function
        end
    end
end)

-- Handle countdown updates - repurpose for drawing time
GameCountdownEvent.OnClientEvent:Connect(function(seconds, phase)
    if phase == "DRAWING" then
        drawingTimeLeft = seconds
        updateTimeDisplay()
        
        -- Auto-submit when time runs out
        if seconds <= 0 and currentGameState == "DRAWING" then
            submitDrawing()
        end
    end
end)

-- Create a timer to periodically check if canvas should be initialized
-- This probably isn't needed, but it's here to be safe
task.spawn(function()
    while task.wait(1) do
        if currentGameState == "DRAWING" and not canvasInitialized then
            log("Drawing phase active but canvas not initialized, attempting to initialize") -- Updated: Use new log function
            initCanvas()
        else
            break
        end
    end
end)