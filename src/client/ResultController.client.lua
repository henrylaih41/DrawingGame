--!native
-- ResultController.client.luau
-- Handles client-side result display UI and logic

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local DebugFlag = false
local DebugUtils = require(ReplicatedStorage.Modules.Services.DebugUtils)

-- Debug logging function using DebugUtils
--- Logs a message to the console if DebugFlag is enabled.
local function log(...)
    if DebugFlag then
        DebugUtils.print("ResultController:", ...)
    end
end

log("Script started")

-- Get services
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local CanvasDraw = require(ReplicatedStorage.Modules.Canvas.CanvasDraw)
local CanvasDisplay = require(ReplicatedStorage.Modules.Canvas.CanvasDisplay)
local GameConstants = require(ReplicatedStorage.Modules.GameData.GameConstants)
-- Remote events
local Events = ReplicatedStorage:WaitForChild("Events")

-- Result display variables
local resultScreen = nil
local topLevelContainer = nil
local resultCanvas = nil
local bestScoreCanvas = nil
local bestScoreContainer = nil
local resultCanvasTopBar = nil
local resultTrophyContainer = nil
local bestScoreTrophyContainer = nil
local feedbackContainer = nil
local feedbackLabel = nil
local feedbackButton, menuButton, bestScoreButton = nil, nil, nil

-- Function to display the final results
--- Displays the results for a specific player.
--- @param playerScore table A table containing the result information for the player.
--- Expected structure:
--- {
---    drawing = ImageData, -- The drawing data to display.
---    score = number,      -- The score (0-10) to display as stars.
---    feedback = string    -- The feedback text to display.
--- }
local function displayResults(playerScore, bestScore)
    assert(playerScore ~= nil, "Result data is nil")
    assert(playerScore.drawing ~= nil, "Result drawing is nil")
    assert(playerScore.score ~= nil, "Result score is nil")
    assert(playerScore.feedback ~= nil, "Result feedback is nil")
    assert(resultCanvas ~= nil, "Result Canvas is nil for displaying results")
    assert(feedbackLabel ~= nil, "Feedback label is nil")
    assert(resultTrophyContainer ~= nil, "Star container is nil")

    log("Displaying results...")

    -- Display the winning drawing
    CanvasDisplay.displayDrawingData(resultCanvas, playerScore.drawing)
    resultCanvas:Render()

    -- Update the star rating
    CanvasDisplay.updateStarDisplay(resultTrophyContainer, playerScore.score, true)

    -- Show result UI once the image is loaded.
    resultScreen.Enabled = true
    topLevelContainer.Visible = true

    -- Update the feedback text
    feedbackLabel.Text = playerScore.feedback
    feedbackLabel.Visible = true -- Ensure feedback label is visible
    
    -- Display the best score if it exists
    if bestScore.drawing then
        -- -- Update the best score canvas
        CanvasDisplay.displayDrawingData(bestScoreCanvas, bestScore.drawing)
        bestScoreCanvas:Render()
        log("Best score" .. bestScore.score)
        CanvasDisplay.updateStarDisplay(bestScoreTrophyContainer, bestScore.score, false)
    else 
        bestScoreCanvas:Clear()
        CanvasDisplay.clearStarDisplay(bestScoreTrophyContainer)
    end
end


-- Function to initialize the result UI
--- Finds and initializes the necessary UI elements for the result screen,
--- including the canvas, star container, feedback label, and star images.
--- Creates the CanvasDraw instance. Prevents multiple initializations.
local function initResultUI()
    log("Initializing Result UI")

    -- Get result screen
    resultScreen = PlayerGui:WaitForChild("ResultScreen") -- Renamed from VotingScreenA
    topLevelContainer = resultScreen:WaitForChild("TopLevelContainer")
    assert(resultScreen ~= nil, "ResultScreen not found in PlayerGui")

    local canvasContainer = topLevelContainer:WaitForChild("CanvasContainer")
    bestScoreContainer = topLevelContainer:WaitForChild("BestScoreContainer")
    local resultCanvasFrame = canvasContainer:WaitForChild("CanvasFrame")
    local bestScoreCanvasFrame = bestScoreContainer:WaitForChild("CanvasFrame")

    local trophyFrame = topLevelContainer:WaitForChild("TrophyFrame")
    local bestScoreTrophyFrame = bestScoreContainer:WaitForChild("TrophyFrame")
    resultCanvasTopBar = canvasContainer:WaitForChild("CanvasTopBar")
    -- Get references to result-specific UI elements
    resultTrophyContainer = trophyFrame:WaitForChild("TrophyContainer")
    bestScoreTrophyContainer = bestScoreTrophyFrame:WaitForChild("TrophyContainer")

    local bench = trophyFrame:WaitForChild("Bench")
    local buttons = bench:WaitForChild("Buttons")
    feedbackContainer = resultCanvasFrame:WaitForChild("FeedbackContainer")
    feedbackLabel = feedbackContainer:WaitForChild("FeedbackLabel")
    feedbackButton = buttons:WaitForChild("FeedbackButton")
    menuButton = buttons:WaitForChild("MenuButton")
    bestScoreButton = buttons:WaitForChild("BestScoreButton")
    assert(resultTrophyContainer ~= nil, "TrophyContainer not found in ResultScreen")
    assert(feedbackLabel ~= nil, "FeedbackLabel not found in ResultScreen")
    assert(feedbackLabel:IsA("TextLabel"), "FeedbackLabel must be a TextLabel")
    
    -- Add click handler for feedback button
    feedbackButton.MouseButton1Click:Connect(function()
        log("Feedback button clicked" .. tostring(feedbackContainer.Visible))
        -- Toggle the visibility of the feedback container
        feedbackContainer.Visible = not feedbackContainer.Visible
    end)

    bestScoreButton.MouseButton1Click:Connect(function()
        log("Best score button clicked" .. tostring(bestScoreContainer.Visible))
        -- Toggle the visibility of the feedback container
        bestScoreContainer.Visible = not bestScoreContainer.Visible
    end)

    menuButton.MouseButton1Click:Connect(function()
        log("Menu button clicked - returning to main menu")
        -- Send the event to server
        Events.ReturnToMainMenu:FireServer()
    end)
    
    -- Create a canvas for the drawing display
    if not resultCanvas then -- Create canvas only if it doesn't exist
        local canvasWidth, canvasHeight = math.ceil(resultCanvasFrame.AbsoluteSize.X), math.ceil(resultCanvasFrame.AbsoluteSize.Y)
        local scaledWidth, scaledHeight, _ = CanvasDraw.scaleCanvasDimensions(canvasWidth, canvasHeight)
        resultCanvas = CanvasDraw.new(resultCanvasFrame, Vector2.new(scaledWidth, scaledHeight))
        resultCanvas.AutoRenderFpsLimit = 1
         log("Canvas: Created")
    else
         log("Canvas: Already exists")
    end

    if not bestScoreCanvas then
        local canvasWidth, canvasHeight = math.ceil(resultCanvasFrame.AbsoluteSize.X), math.ceil(resultCanvasFrame.AbsoluteSize.Y)
        local scaledWidth, scaledHeight, _ = CanvasDraw.scaleCanvasDimensions(canvasWidth, canvasHeight)
        bestScoreCanvas = CanvasDraw.new(bestScoreCanvasFrame, Vector2.new(scaledWidth, scaledHeight))
        bestScoreCanvas.AutoRenderFpsLimit = 1
        log("Best Score Canvas: Created")
    else
        log("Best Score Canvas: Already exists")
    end
    
    assert(resultCanvas ~= nil, "Failed to create or find canvas")
    log("Result UI initialized successfully")
end

local function updateDrawingDisplayForTheme(drawingData)
    bestScoreCanvas:Clear()
    CanvasDisplay.displayDrawingData(bestScoreCanvas, drawingData.imageData)
    CanvasDisplay.updateStarDisplay(bestScoreTrophyContainer, drawingData.score, false)
end

Events.ReceiveNewBestDrawing.OnClientEvent:Connect(function(drawingData)
    updateDrawingDisplayForTheme(drawingData)
end)

-- Handle game state changes
--- Handles game state changes received from the server via GameStateChanged event.
--- Initializes UI if needed, shows/hides the screen based on game state,
--- and displays results when in RESULTS state.
--- @param stateData table Data containing the current game state and additional information.
Events.GameStateChanged.OnClientEvent:Connect(function(stateData)
    assert(stateData ~= nil, "ResultController: stateData is nil")
    local theme = stateData.theme
    log("ResultController: Game State Changed: ", stateData.state)


    if stateData.state == GameConstants.PlayerStateEnum.RESULTS then
        -- Ensure UI is initialized. Init upon the first call.
        -- Initially hide the feedback container until button is clicked
        feedbackContainer.Visible = false
        bestScoreContainer.Visible = false
        -- Set the theme text
        resultCanvasTopBar.Theme.Text = theme.Name 
        if theme.Difficulty then
            resultCanvasTopBar.Theme.Text = resultCanvasTopBar.Theme.Text .. " [" .. theme.Difficulty .. "]"
        end
        assert(resultScreen ~= nil, "ResultScreen is nil when trying to display results")

        -- Check if we have results data
        if stateData.playerScores then
            -- Store the results data
            -- Display the results for current player
            displayResults(stateData.playerScores, stateData.bestScore)
        else
            warn("ResultController: Received RESULTS state but no resultsData was provided.")
            -- Display error message or hide elements
            if feedbackLabel then
                feedbackLabel.Text = "Results are unavailable."
                feedbackLabel.Visible = true
            else
                warn("ResultController: FeedbackLabel not found to display error.")
            end
            if resultTrophyContainer then resultTrophyContainer.Visible = false end
            if resultCanvas then resultCanvas:Clear() end
        end
    else
        -- Hide UI for other states (e.g., LOBBY, DRAWING)
        if topLevelContainer then
            topLevelContainer.Visible = false
            resultScreen.Enabled = false
            log("ResultScreen topLevelContainer hidden")
        end

        if resultCanvas then resultCanvas:Clear() end
    end
end)

initResultUI()
log("ResultController script loaded") 