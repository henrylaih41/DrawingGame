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
local DEFAULT_COLOR = Color3.new(0, 0, 0) -- Black
local CURRENT_COLOR = DEFAULT_COLOR
local BRUSH_SIZE = 5
local IS_DRAWING = false
local canvas = nil -- Canvas object reference
local drawingScreen = nil -- Reference to the DrawingScreen UI
local currentGameState = "LOBBY"
local drawingTimeLeft = 0
local canvasInitialized = false -- Flag to track canvas initialization

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
local function updateBrushSize(sizeSlider, sizeValue)
    local sliderPosition = sizeSlider.AbsolutePosition
    local sliderSize = sizeSlider.AbsoluteSize
    local mousePosition = UserInputService:GetMouseLocation() - Vector2.new(0, game:GetService("GuiService"):GetGuiInset().Y)
    
    -- Calculate relative position (0-1)
    local relativeX = math.clamp((mousePosition.X - sliderPosition.X) / sliderSize.X, 0, 1)
    
    -- Convert to brush size (1-20)
    BRUSH_SIZE = math.floor(1 + relativeX * 19)
    sizeValue.Text = tostring(BRUSH_SIZE)
    log("Brush size updated to:", BRUSH_SIZE) -- Updated: Use new log function
end

-- Function to initialize the canvas
local function initCanvas()
    -- Prevent multiple initializations
    if canvasInitialized then
        log("Canvas already initialized, skipping initialization") -- Updated: Use new log function
        return
    end
    
    -- Set initialization flag to true
    canvasInitialized = true

    log("initCanvas function started") -- Updated: Use new log function
    
    drawingScreen = PlayerGui:WaitForChild("DrawingScreen")
    
    -- Get UI references
    local canvasFrame = drawingScreen.CanvasContainer.Canvas
    local controls = drawingScreen.Controls
    
    -- Create canvas with CanvasDraw
    if canvas then
        canvas:Destroy()
    end
    
    -- Use the actual frame size instead of a fixed resolution
    local frameSize = canvasFrame.AbsoluteSize
    log("Frame size:", frameSize.X, ",", frameSize.Y) -- Updated: Use new log function
    canvas = CanvasDraw.new(canvasFrame, Vector2.new(math.ceil(frameSize.X), math.ceil(frameSize.Y)))
    canvas:Clear(Color3.new(1, 1, 1)) -- Start with white background
    canvas.GridEnabled = false  -- Disable grid
    canvas.AutoRender = true    -- Enable auto rendering
    
    -- Add variable to track previous drawing position
    local prevCanvasX = nil
    local prevCanvasY = nil

    -- Set up color picker
    local c = Color.New(drawingScreen)
    c:SetColor(CURRENT_COLOR)
    
    c.Updated:Connect(function(color)
        CURRENT_COLOR = color
    end)

    -- for colorName, colorValue in pairs(colorButtons) do
    --     local button = colorPalette:FindFirstChild(colorName)
    --     if button then
    --         log("Setting up", colorName, "button") -- Updated: Use new log function
    --         button.BackgroundColor3 = colorValue
    --         button.MouseButton1Click:Connect(function()
    --             CURRENT_COLOR = colorValue
    --             log("Color changed to:", colorName) -- Updated: Use new log function
    --         end)
    --     else
    --         warn("Color button not found: " .. colorName)
    --     end
    -- end
    
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
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDraggingSlider = true
            updateBrushSize(sizeSlider, sizeValue)
        end
    end)
    
    sizeSlider.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDraggingSlider = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if isDraggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateBrushSize(sizeSlider, sizeValue)
        end
    end)

    -- Drawing functionality
    local function handleDrawing(input)
        if not isCanvasEnabled() or not canvas then return end
        
        -- For MouseMovement inputs, we rely on IS_DRAWING flag being set
        -- For MouseButton1 inputs, this is the initial click
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and 
           input.UserInputType ~= Enum.UserInputType.MouseMovement then 
            return 
        end
        
        -- Get the absolute position and size of the canvas frame
        -- IMPORTANT: We must get these values EVERY time to prevent misalignment
        local canvasPosition = canvasFrame.AbsolutePosition
        local canvasSize = canvasFrame.AbsoluteSize
        
        -- Get the mouse position with accurate GuiInset calculation
        local mousePos = UserInputService:GetMouseLocation()
        local inset = game:GetService("GuiService"):GetGuiInset()
        mousePos = mousePos - Vector2.new(0, inset.Y)
        
        log("Mouse position:", mousePos.X, ",", mousePos.Y, "| Canvas position:", -- Updated: Use new log function
                  canvasPosition.X, ",", canvasPosition.Y, "| Canvas size:",
                  canvasSize.X, ",", canvasSize.Y)
        
        -- Check if mouse is inside the canvas
        if mousePos.X >= canvasPosition.X and
           mousePos.X <= canvasPosition.X + canvasSize.X and
           mousePos.Y >= canvasPosition.Y and
           mousePos.Y <= canvasPosition.Y + canvasSize.Y then
            
            log("Mouse is inside canvas boundaries") -- Updated: Use new log function
            
            -- Calculate relative position within the canvas (0-1)
            local relX = (mousePos.X - canvasPosition.X) / canvasSize.X
            local relY = (mousePos.Y - canvasPosition.Y) / canvasSize.Y
            
            -- Convert to canvas pixel coordinates - use math.round for more precise positioning
            local canvasX = math.round(relX * canvasSize.X)
            local canvasY = math.round(relY * canvasSize.Y)
            
            log("Drawing at canvas position:", canvasX, ",", canvasY, -- Updated: Use new log function
                     "| Relative position:", relX, ",", relY,
                     "| Using brush size:", BRUSH_SIZE,
                     "| Using color:", tostring(CURRENT_COLOR))
            
            -- Draw a circle at the mouse position
            if canvas then
                -- If we have a previous position and we're in the middle of drawing,
                -- draw a line to connect the dots
                if prevCanvasX and prevCanvasY and IS_DRAWING then
                    -- Calculate distance between points
                    local distance = math.sqrt((canvasX - prevCanvasX)^2 + (canvasY - prevCanvasY)^2)
                    
                    -- Only draw a line if points are far enough apart (prevents duplicate circles)
                    if distance > BRUSH_SIZE * 0.5 then
                        -- Draw line between previous point and current point for smoothing
                        canvas:DrawLineXY(prevCanvasX, prevCanvasY, canvasX, canvasY, CURRENT_COLOR, BRUSH_SIZE, true)
                    end
                end
                
                -- Always draw a circle at the current position for consistent brush appearance
                canvas:DrawCircleXY(canvasX, canvasY, BRUSH_SIZE, CURRENT_COLOR, 1, true)
                
                -- Update previous position for next drawing operation
                prevCanvasX = canvasX
                prevCanvasY = canvasY
            else
                warn("Cannot draw - canvas object is nil")
            end
        else
            log("Mouse position outside canvas boundaries") -- Updated: Use new log function
        end
    end
    
    -- Connect drawing input handlers
    UserInputService.InputBegan:Connect(function(input)
        log("InputBegan event received") -- Updated: Use new log function
        if currentGameState == "DRAWING" and input.UserInputType == Enum.UserInputType.MouseButton1 then
            IS_DRAWING = true
            handleDrawing(input)
        end
    end)
    
    -- Mouse button up - stop drawing and reset previous position
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            IS_DRAWING = false
            -- Reset previous position when we stop drawing
            prevCanvasX = nil
            prevCanvasY = nil
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        log("InputChanged event received") -- Updated: Use new log function
        if IS_DRAWING and input.UserInputType == Enum.UserInputType.MouseMovement and currentGameState == "DRAWING" then
            handleDrawing(input)
        end
    end)
    
    log("Canvas initialization complete") -- Updated: Use new log function
end

-- Function to update the drawing time display
local function updateTimeDisplay()
    if drawingScreen and drawingScreen:WaitForChild("TimeLabel") then
        local minutes = math.floor(drawingTimeLeft / 60)
        local seconds = drawingTimeLeft % 60
        drawingScreen.TimeLabel.Text = string.format("Time Remaining: %d:%02d", minutes, seconds)
        
        -- Make time red when less than 30 seconds
        if drawingTimeLeft <= 30 then
            drawingScreen.TimeLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
        else
            drawingScreen.TimeLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
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