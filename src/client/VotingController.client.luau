--!native
-- VotingController.client.luau
-- Handles client-side voting UI and logic

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local DebugUtils = require(ReplicatedStorage.Modules.Services.DebugUtils)
local DebugFlag = false

-- Debug logging function using DebugUtils
local function log(...)
    -- Check if DebugUtils is enabled before printing
    if DebugFlag then
        DebugUtils.print("VotingController:", ...)
    end
end

log("Script started")

-- Get services
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local CanvasDraw = require(ReplicatedStorage.Modules.Canvas.CanvasDraw)
local ImageDataConstructor = require(ReplicatedStorage.Modules.Canvas.ImageDataConstructor)

-- Remote events
local Events = ReplicatedStorage:WaitForChild("Events")
local GameStateChangedEvent = Events:WaitForChild("GameStateChanged")
local GameCountdownEvent = Events:WaitForChild("GameCountdown")
local DrawingsReceivedEvent = Events:WaitForChild("DrawingsReceived")
local SubmitVoteEvent = Events:WaitForChild("SubmitVote")

-- Voting variables
local currentGameState = "LOBBY"
local votingScreen = nil
local allDrawings = {}
local currentDrawingIndex = 1
local votingTimeLeft = 0
local hasVoted = false
local votingInitialized = false
local canvas = nil

-- Function to display an image from ImageData
local function displayDrawingData(canvas, imageData)
    assert(canvas ~= nil, "Canvas is nil")
    assert(imageData ~= nil, "ImageData is nil")
    -- Clear any existing content
    canvas:Clear()
    local reconstructedImage =
        ImageDataConstructor.new(imageData.Width, imageData.Height, imageData.ImageBuffer)
    local scaleX = canvas.Resolution.X / reconstructedImage.Width
    local scaleY = canvas.Resolution.Y / reconstructedImage.Height
    canvas:DrawImage(reconstructedImage, Vector2.new(1, 1), Vector2.new(scaleX, scaleY))
end

-- Function to display the current drawing
local function displayCurrentDrawing()
    if not votingScreen or #allDrawings == 0 then return end
    
    local currentDrawing = allDrawings[currentDrawingIndex]
    if not currentDrawing then return end
    
    -- Display the drawing
    displayDrawingData(canvas, currentDrawing.imageData)
    
    log("Displaying drawing", currentDrawingIndex, "by player", currentDrawing.playerId)
end

-- Function to update the timer display
local function updateTimeDisplay()
    if votingScreen and votingScreen:FindFirstChild("TimeLabel") then
        local minutes = math.floor(votingTimeLeft / 60)
        local seconds = votingTimeLeft % 60
        votingScreen.TimeLabel.Text = string.format("Time Left: %d:%02d", minutes, seconds)
        
        -- Make time red when less than 30 seconds
        if votingTimeLeft <= 30 then
            votingScreen.TimeLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
        else
            votingScreen.TimeLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
        end
    end
end

-- Function to show notification
local function showNotification(message, duration)
    if votingScreen and votingScreen:FindFirstChild("Notification") then
        local notification = votingScreen.Notification
        notification.Text = message
        notification.Visible = true
        
        task.delay(duration, function()
            notification.Visible = false
        end)
    end
end

-- Function to initialize the voting UI
local function initVotingUI()
    -- Prevent multiple initializations
    if votingInitialized then
        log("Voting UI already initialized")
        return
    end
    
    votingInitialized = true
    log("Initializing voting UI")
    
    -- Get or create voting screen
    votingScreen = PlayerGui:WaitForChild("VotingScreen")
    log("VotingScreen:", votingScreen.Name)
    -- Set up navigation buttons
    local nextButton = votingScreen:WaitForChild("NextButton")
    local prevButton = votingScreen:WaitForChild("PrevButton")
    local voteButton = votingScreen:WaitForChild("VoteButton")
    log("NextButton:", nextButton.Name)
    log("PrevButton:", prevButton.Name)
    log("VoteButton:", voteButton.Name)
    local displayContainer = votingScreen:WaitForChild("DrawingDisplayContainer")
    log("DisplayContainer:", displayContainer.Name)
    local displayFrame = displayContainer:WaitForChild("DrawingDisplay")
    log("DisplayFrame:", displayFrame.Name)

    log("DisplayFrame Size:", displayFrame.AbsoluteSize.X, displayFrame.AbsoluteSize.Y)

    -- Create a canvas for the drawing display
    canvas = CanvasDraw.new(displayFrame, Vector2.new(math.ceil(displayFrame.AbsoluteSize.X), math.ceil(displayFrame.AbsoluteSize.Y)))
    log("Canvas: Created")

    -- Handle next button
    nextButton.MouseButton1Click:Connect(function()
        if #allDrawings <= 1 then return end
        
        currentDrawingIndex = currentDrawingIndex + 1
        if currentDrawingIndex > #allDrawings then
            currentDrawingIndex = 1 -- Wrap around
        end
        
        displayCurrentDrawing()
    end)
    
    -- Handle previous button
    prevButton.MouseButton1Click:Connect(function()
        if #allDrawings <= 1 then return end
        
        currentDrawingIndex = currentDrawingIndex - 1
        if currentDrawingIndex < 1 then
            currentDrawingIndex = #allDrawings -- Wrap around
        end
        
        displayCurrentDrawing()
    end)
    
    -- Handle vote button
    voteButton.MouseButton1Click:Connect(function()
        if hasVoted then
            showNotification("You've already voted!", 2)
            return
        end
        
        if #allDrawings == 0 then
            showNotification("No drawings to vote for!", 2)
            return
        end
        
        -- Get current drawing's player ID
        local currentDrawing = allDrawings[currentDrawingIndex]
        if not currentDrawing then 
            assert(false, "Current drawing is nil when trying to vote.")
            return 
        end
        
        -- Submit vote to server
        SubmitVoteEvent:FireServer(currentDrawing.playerId)
        
        -- Update UI to reflect vote
        hasVoted = true
        voteButton.Text = "Voted!"
        voteButton.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
        
        showNotification("Vote submitted!", 2)
    end)
    
    log("Voting UI initialized successfully")
end

-- Handle game state changes
GameStateChangedEvent.OnClientEvent:Connect(function(newState)
    log("Game state changed:", newState)
    currentGameState = newState
    
    if newState == "VOTING" then
        -- Initialize voting UI if not already done
        if not votingInitialized then
            initVotingUI()
        end
        
        -- Reset voting state
        hasVoted = false
        
        -- Show voting UI
        if votingScreen then
            -- TODO: Use Visible instead of Enabled for ScreenGUI
            votingScreen.Enabled = true
            
            -- Reset vote button
            local voteButton = votingScreen:FindFirstChild("VoteButton")
            if voteButton then
                voteButton.Text = "Vote for this drawing!"
                voteButton.BackgroundColor3 = Color3.fromRGB(255, 200, 100)
            end
            
            showNotification("Time to vote for your favorite drawing!", 3)
        end
    else
        -- Hide voting UI for other states
        if votingScreen then
            -- TODO: Use Visible instead of Enabled for ScreenGUI
            votingScreen.Enabled = false
        end
    end
end)

-- Handle drawings received from server
DrawingsReceivedEvent.OnClientEvent:Connect(function(drawings)
    log("Received", #drawings, "drawings from server")
    initVotingUI()
    
    -- Store received drawings
    allDrawings = drawings
    
    -- Filter out own drawing
    local filteredDrawings = {}
    for _, drawing in ipairs(drawings) do
        if drawing.playerId ~= LocalPlayer.UserId then
            table.insert(filteredDrawings, drawing)
        end
    end
    
    -- Update display if we're in voting state
    if currentGameState == "VOTING" then
        currentDrawingIndex = 1
        displayCurrentDrawing()
    end
end)

-- Handle countdown updates
GameCountdownEvent.OnClientEvent:Connect(function(seconds, phase)
    if not votingInitialized then
        log("Countdown update received but voting UI not initialized yet. Phase:", phase)
        return
    end
    
    if phase == "VOTING" then
        votingTimeLeft = seconds
        updateTimeDisplay()
    end
end)

-- Initialize if game is already in voting state
if currentGameState == "VOTING" then
    initVotingUI()
end

log("VotingController script loaded") 