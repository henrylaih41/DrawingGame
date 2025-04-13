--!native
-- DrawingCanvas.client.luau
-- Interactive drawing canvas implementation using the CanvasDraw module
-- Integrated with game state management

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

-- Create debug function
local function DebugLog(message)
    print("DrawingCanvas DEBUG: " .. message)
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
local SubmitDrawingEvent = Events:WaitForChild("SubmitDrawing", 10) or Instance.new("RemoteEvent", Events)
if SubmitDrawingEvent.Name ~= "SubmitDrawing" then
    SubmitDrawingEvent.Name = "SubmitDrawing"
end

local LocalPlayer = Players.LocalPlayer
DebugLog("LocalPlayer reference acquired: " .. tostring(LocalPlayer))
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
DebugLog("PlayerGui reference acquired")

-- Configuration
local CANVAS_RESOLUTION = Vector2.new(512, 512)
local DEFAULT_COLOR = Color3.new(0, 0, 0) -- Black
local CURRENT_COLOR = DEFAULT_COLOR
local BRUSH_SIZE = 5
local IS_DRAWING = false
local canvas = nil -- Canvas object reference
local drawingScreen = nil -- Reference to the DrawingScreen UI
local currentGameState = "LOBBY"
local drawingTimeLeft = 0

-- Function to check if canvas UI is enabled/visible
local function isCanvasEnabled()
    if not drawingScreen then
        return false
    end
    
    -- Check if the ScreenGui is enabled
    if drawingScreen:IsA("ScreenGui") then
        return drawingScreen.Enabled
    end
    
    -- Fall back to visibility check for other UI types
    local success, isVisible = pcall(function() 
        return drawingScreen.Visible 
    end)
    
    return success and isVisible
end

-- Function to initialize the canvas
local function initCanvas()
    DebugLog("initCanvas function started")
    
    -- Check if we already have the DrawingScreen UI
    if PlayerGui:FindFirstChild("DrawingScreen") then
        drawingScreen = PlayerGui:FindFirstChild("DrawingScreen")
        DebugLog("Existing DrawingScreen found")
    else 
        DebugLog("DrawingScreen not found, waiting for it to be created")
        assert(false, "DrawingScreen not found in PlayerGui")
    end
    
    -- Get UI references
    local canvasFrame = drawingScreen.CanvasContainer.Canvas
    local controls = drawingScreen.Controls
    local colorPalette = controls.ColorPalette
    
    -- Create canvas with CanvasDraw
    if canvas then
        canvas:Destroy()
    end
    
    canvas = CanvasDraw.new(canvasFrame, CANVAS_RESOLUTION)
    canvas:Clear(Color3.new(1, 1, 1)) -- Start with white background
    canvas.GridEnabled = false  -- Disable grid
    canvas.AutoRender = true    -- Enable auto rendering
    
    DebugLog("Canvas created successfully")
    
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
        
        -- Only draw on left click
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        
        -- Get the absolute position and size of the canvas frame
        local canvasPosition = canvasFrame.AbsolutePosition
        local canvasSize = canvasFrame.AbsoluteSize
        
        -- Get the mouse position
        local mousePos = UserInputService:GetMouseLocation() - Vector2.new(0, game:GetService("GuiService"):GetGuiInset().Y)
        
        -- Check if mouse is inside the canvas
        if mousePos.X >= canvasPosition.X and
           mousePos.X <= canvasPosition.X + canvasSize.X and
           mousePos.Y >= canvasPosition.Y and
           mousePos.Y <= canvasPosition.Y + canvasSize.Y then
            
            -- Calculate relative position within the canvas (0-1)
            local relX = (mousePos.X - canvasPosition.X) / canvasSize.X
            local relY = (mousePos.Y - canvasPosition.Y) / canvasSize.Y
            
            -- Convert to canvas pixel coordinates
            local canvasX = math.floor(relX * CANVAS_RESOLUTION.X)
            local canvasY = math.floor(relY * CANVAS_RESOLUTION.Y)
            
            DebugLog("Drawing at canvas position: " .. canvasX .. ", " .. canvasY)
            
            -- Draw a circle at the mouse position
            if canvas then
                canvas:DrawCircleXY(canvasX, canvasY, BRUSH_SIZE, CURRENT_COLOR, 1, true)
            else
                warn("Cannot draw - canvas object is nil")
            end
        end
    end
    
    -- Connect drawing input handlers
    UserInputService.InputBegan:Connect(function(input)
        if currentGameState == "DRAWING" then
            IS_DRAWING = true
            handleDrawing(input)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            IS_DRAWING = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if IS_DRAWING and input.UserInputType == Enum.UserInputType.MouseMovement and currentGameState == "DRAWING" then
            handleDrawing(input)
        end
    end)
    
    DebugLog("Canvas initialization complete")
end

-- Function to show notification
local function showNotification(message, duration)
    duration = duration or 3
    
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
        return canvas:SaveToImageData()
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
        if not canvas then
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

-- Try to initialize the canvas
initCanvas()

-- Create a timer to periodically check if canvas should be initialized
local checkCanvasTimer = nil
checkCanvasTimer = task.spawn(function()
    while task.wait(1) do
        if currentGameState == "DRAWING" and not canvas then
            DebugLog("Drawing phase active but canvas not initialized, attempting to initialize")
            initCanvas()
        end
    end
end) 