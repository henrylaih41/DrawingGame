--!native
-- DrawingCanvas.client.luau
-- Interactive drawing canvas implementation using the CanvasDraw module
-- Integrated with game state management

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local DebugFlag = true

-- Create debug function
local function DebugLog(message)
    if DebugFlag then
        print("DrawingCanvas DEBUG: " .. message)
    end
end

DebugLog("Script started")

-- Get the CanvasDraw module
local CanvasDraw = nil
local success, error = pcall(function()
    CanvasDraw = require(ReplicatedStorage.Modules.Canvas.CanvasDraw)
    DebugLog("CanvasDraw module loaded successfully")
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
DebugLog("LocalPlayer reference acquired: " .. tostring(LocalPlayer))
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
DebugLog("PlayerGui reference acquired")

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
        DebugLog("Drawing saved successfully, submitting to server")
        
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

-- Function to initialize the canvas
local function initCanvas()
    -- Prevent multiple initializations
    if canvasInitialized then
        DebugLog("Canvas already initialized, skipping initialization")
        return
    end
    
    -- Set initialization flag to true
    canvasInitialized = true

    DebugLog("initCanvas function started")
    
    drawingScreen = PlayerGui:WaitForChild("DrawingScreen")
    
    -- Get UI references
    local canvasFrame = drawingScreen.CanvasContainer.Canvas
    local controls = drawingScreen.Controls
    local colorPalette = controls.ColorPalette
    
    -- Create canvas with CanvasDraw
    if canvas then
        canvas:Destroy()
    end
    
    -- Use the actual frame size instead of a fixed resolution
    local frameSize = canvasFrame.AbsoluteSize
    DebugLog("Frame size: " .. frameSize.X .. ", " .. frameSize.Y)  
    canvas = CanvasDraw.new(canvasFrame, Vector2.new(frameSize.X, frameSize.Y))
    canvas:Clear(Color3.new(1, 1, 1)) -- Start with white background
    canvas.GridEnabled = false  -- Disable grid
    canvas.AutoRender = true    -- Enable auto rendering
    
    -- Add variable to track previous drawing position
    local prevCanvasX = nil
    local prevCanvasY = nil
    
    -- Set up color buttons
    local colorButtons = {
        ["Black"] = Color3.new(0, 0, 0),
        ["Red"] = Color3.new(1, 0, 0),
        ["Green"] = Color3.new(0, 1, 0),
        ["Blue"] = Color3.new(0, 0, 1),
        ["Yellow"] = Color3.new(1, 1, 0),
        ["Purple"] = Color3.new(0.7, 0, 1),
        ["White"] = Color3.new(1, 1, 1),
    }
    
    for colorName, colorValue in pairs(colorButtons) do
        local button = colorPalette:FindFirstChild(colorName)
        if button then
            DebugLog("Setting up " .. colorName .. " button")
            button.BackgroundColor3 = colorValue
            button.MouseButton1Click:Connect(function()
                CURRENT_COLOR = colorValue
                DebugLog("Color changed to: " .. colorName)
            end)
        else
            warn("Color button not found: " .. colorName)
        end
    end
    
    -- Clear button functionality
    local clearButton = controls:WaitForChild("ClearButton")
    DebugLog("ClearButton found")
    
    clearButton.MouseButton1Click:Connect(function()
        DebugLog("Clear button clicked")
        if canvas then
            canvas:Clear(Color3.new(1, 1, 1)) -- Clear to white
            DebugLog("Canvas cleared")
        else
            warn("Cannot clear canvas - canvas object is nil")
        end
    end)
    
    -- Submit button functionality 
    local submitButton = controls:WaitForChild("SubmitButton")
    DebugLog("SubmitButton found")
    
    submitButton.MouseButton1Click:Connect(function()
        DebugLog("Submit button clicked")
        submitDrawing()
    end)
    
    -- Brush size slider functionality
    local sizeSlider = controls:WaitForChild("SizeSlider")
    DebugLog("SizeSlider found")
    
    local sizeValue = controls:WaitForChild("SizeValue")
    DebugLog("SizeValue found")
    
    -- Use UserInputService to handle slider interaction
    local isDraggingSlider = false
    
    sizeSlider.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDraggingSlider = true
            updateBrushSize(input)
        end
    end)
    
    sizeSlider.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDraggingSlider = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if isDraggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateBrushSize(input)
        end
    end)
    
    -- Function to update brush size based on slider position
    function updateBrushSize(input)
        local sliderPosition = sizeSlider.AbsolutePosition
        local sliderSize = sizeSlider.AbsoluteSize
        local mousePosition = UserInputService:GetMouseLocation() - Vector2.new(0, game:GetService("GuiService"):GetGuiInset().Y)
        
        -- Calculate relative position (0-1)
        local relativeX = math.clamp((mousePosition.X - sliderPosition.X) / sliderSize.X, 0, 1)
        
        -- Convert to brush size (1-20)
        BRUSH_SIZE = math.floor(1 + relativeX * 19)
        sizeValue.Text = tostring(BRUSH_SIZE)
        DebugLog("Brush size updated to: " .. BRUSH_SIZE)
    end
    
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
        
        DebugLog("Mouse position: " .. mousePos.X .. ", " .. mousePos.Y .. " | Canvas position: " .. 
                  canvasPosition.X .. ", " .. canvasPosition.Y .. " | Canvas size: " .. 
                  canvasSize.X .. ", " .. canvasSize.Y)
        
        -- Check if mouse is inside the canvas
        if mousePos.X >= canvasPosition.X and
           mousePos.X <= canvasPosition.X + canvasSize.X and
           mousePos.Y >= canvasPosition.Y and
           mousePos.Y <= canvasPosition.Y + canvasSize.Y then
            
            DebugLog("Mouse is inside canvas boundaries")
            
            -- Calculate relative position within the canvas (0-1)
            local relX = (mousePos.X - canvasPosition.X) / canvasSize.X
            local relY = (mousePos.Y - canvasPosition.Y) / canvasSize.Y
            
            -- Convert to canvas pixel coordinates - use math.round for more precise positioning
            local canvasX = math.round(relX * canvasSize.X)
            local canvasY = math.round(relY * canvasSize.Y)
            
            DebugLog("Drawing at canvas position: " .. canvasX .. ", " .. canvasY .. 
                     " | Relative position: " .. relX .. ", " .. relY ..
                     " | Using brush size: " .. BRUSH_SIZE .. 
                     " | Using color: " .. tostring(CURRENT_COLOR))
            
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
            DebugLog("Mouse position outside canvas boundaries")
        end
    end
    
    -- Connect drawing input handlers
    UserInputService.InputBegan:Connect(function(input)
        DebugLog("InputBegan event received")
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
        DebugLog("InputChanged event received")
        if IS_DRAWING and input.UserInputType == Enum.UserInputType.MouseMovement and currentGameState == "DRAWING" then
            handleDrawing(input)
        end
    end)
    
    DebugLog("Canvas initialization complete")
end


-- Function to update the drawing time display
local function updateTimeDisplay()
    if drawingScreen and drawingScreen:FindFirstChild("TimeLabel") then
        local minutes = math.floor(drawingTimeLeft / 60)
        local seconds = drawingTimeLeft % 60
        drawingScreen.TimeLabel.Text = string.format("Time Remaining: %d:%02d", minutes, seconds)
        
        -- Make time red when less than 30 seconds
        if drawingTimeLeft <= 30 then
            drawingScreen.TimeLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
        else
            drawingScreen.TimeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        end
    end
end

-- Handle game state changes
GameStateChangedEvent.OnClientEvent:Connect(function(newState)
    DebugLog("Game state changed to: " .. newState)
    currentGameState = newState
    
    if newState == "DRAWING" then
        -- Initialize canvas if not already done
        if not canvasInitialized then
            initCanvas()
        end
        
        -- Show drawing UI
        if drawingScreen then
            drawingScreen.Enabled = true
            showNotification("Start drawing now!", 3)
        end
    else
        -- Hide drawing UI for other states
        if drawingScreen then
            drawingScreen.Enabled = false
        end
        
        -- If leaving drawing phase and canvas exists, attempt to submit
        if newState == "VOTING" and canvas and currentGameState == "DRAWING" then
            submitDrawing()
        end
    end
    
    -- Reset canvas if returning to lobby
    if newState == "LOBBY" and canvas then
        canvas:Clear(Color3.new(1, 1, 1))
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
local checkCanvasTimer = nil
checkCanvasTimer = task.spawn(function()
    while task.wait(1) do
        if currentGameState == "DRAWING" and not canvasInitialized then
            DebugLog("Drawing phase active but canvas not initialized, attempting to initialize")
            initCanvas()
        else
            break
        end
    end
end) 