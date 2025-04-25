--!native
-- ResultController.client.luau
-- Handles client-side result display UI and logic

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local DebugFlag = true
local DebugUtils = require(ReplicatedStorage.Modules.Services.DebugUtils)
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Debug logging function using DebugUtils
--- Logs a message to the console if DebugFlag is enabled.
--- @param ... any The message parts to log.
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
local ImageDataConstructor = require(ReplicatedStorage.Modules.Canvas.ImageDataConstructor)

-- Remote events
local Events = ReplicatedStorage:WaitForChild("Events")

-- Result display variables
local resultScreen = nil
local resultUIInitialized = false
local canvas = nil
local trophyContainer = nil
local feedbackLabel = nil
local trophies = {} -- Table to hold star ImageLabels

-- Asset IDs for stars (Replace with your actual asset IDs)
local LOW_TROPHY_ASSET = "rbxassetid://70472161727933"
local MID_TROPHY_ASSET = "rbxassetid://119966776084235"
local HIGH_TROPHY_ASSET = "rbxassetid://124414140924737"

-- Function to display an image from ImageData
--- Clears the target canvas and draws the provided image data onto it, scaling to fit.
--- @param targetCanvas CanvasDraw The CanvasDraw instance to draw on.
--- @param imageData table The image data containing Width, Height, and ImageBuffer.
local function displayDrawingData(targetCanvas, imageData)
    assert(targetCanvas ~= nil, "Canvas is nil")
    assert(imageData ~= nil, "ImageData is nil")
    assert(imageData.Width ~= nil and imageData.Height ~= nil and imageData.ImageBuffer ~= nil, "Invalid ImageData structure")

    -- Clear any existing content
    targetCanvas:Clear()
    local reconstructedImage =
        ImageDataConstructor.new(imageData.Width, imageData.Height, imageData.ImageBuffer)
    local scaleX = targetCanvas.Resolution.X / reconstructedImage.Width
    local scaleY = targetCanvas.Resolution.Y / reconstructedImage.Height
    targetCanvas:DrawImage(reconstructedImage, Vector2.new(1, 1), Vector2.new(scaleX, scaleY))
    log("Drawing displayed on canvas")
end

-- Function to create a starburst effect
local function createStarburstEffect(parent)
    for i = 1, 8 do
        local spark = Instance.new("Frame")
        spark.BorderSizePixel = 0
        spark.BackgroundColor3 = Color3.fromRGB(255, 255, 150) -- Yellow spark
        spark.Size = UDim2.new(0, 2, 0, 10)
        spark.AnchorPoint = Vector2.new(0.5, 0.5)
        spark.Position = UDim2.new(0.5, 0, 0.5, 0)
        spark.Rotation = i * 45 -- Evenly spaced around
        spark.ZIndex = 10 -- Ensure it appears above the trophy
        spark.Parent = parent
        
        -- Create glow effect
        local uiGradient = Instance.new("UIGradient")
        uiGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 200, 50))
        })
        uiGradient.Parent = spark
        
        -- Animate the spark outward
        local tweenInfo = TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = TweenService:Create(spark, tweenInfo, {
            Size = UDim2.new(0, 2, 0, 40),
            BackgroundTransparency = 1
        })
        tween:Play()
        
        -- Clean up after animation
        tween.Completed:Connect(function()
            spark:Destroy()
        end)
    end
end

-- Function to update the star display based on score
--- Updates the star images (empty/filled) based on the provided score.
--- Handles potential issues with finding star ImageLabels.
--- @param score number The score (0-10) determining the number of filled stars.
local function updateStarDisplay(score)
    assert(type(score) == "number" and score >= 0 and score <= 10, "Score must be a number between 0 and 10" .. score)
    assert(trophyContainer ~= nil, "Star container is nil")
    assert(#trophies == 10, "Expected 10 trophies, found " .. #trophies)
    log("Updating star display for score: ", score)
    score = 10
    
    -- First clean up any previous trophy overlays
    for i, trophyLabel in ipairs(trophies) do
        local existingOverlay = trophyLabel:FindFirstChild("TrophyOverlay")
        if existingOverlay then
            existingOverlay:Destroy()
        end
    end
    
    trophyContainer.Visible = true -- Ensure container is visible
    
    task.wait(1)
    -- Animate trophies sequentially
    for i = 1, score do
        if i <= #trophies then
            task.delay((i - 1) * 0.3, function()
                local trophy = trophies[i]
                if trophy then
                    -- Determine which trophy asset to use
                    local trophyAsset
                    if i == 10 then
                        trophyAsset = HIGH_TROPHY_ASSET -- Special trophy for the 10th trophy at max score
                    elseif i >= 7 then
                        trophyAsset = MID_TROPHY_ASSET -- Use NICE trophy for scores 7-9
                    else -- Score is 1-6
                        trophyAsset = LOW_TROPHY_ASSET -- Use BASIC trophy for scores 1-6
                    end
                    
                    -- Create a new overlay ImageLabel that will be placed on top of the original
                    local overlay = Instance.new("ImageLabel")
                    overlay.Name = "TrophyOverlay"
                    overlay.Image = trophyAsset
                    overlay.BackgroundTransparency = 1
                    overlay.Size = UDim2.new(1, 0, 1, 0)
                    overlay.AnchorPoint = Vector2.new(0.5, 0.5)
                    overlay.Position = UDim2.new(0.5, 0, 0.5, 0)
                    overlay.ZIndex = trophy.ZIndex + 1 -- Ensure it appears above the original trophy
                    
                    -- Create UIScale for scaling animation
                    local uiScale = Instance.new("UIScale")
                    uiScale.Scale = 0 -- Start from zero scale
                    uiScale.Parent = overlay
                    
                    -- Add the overlay to the trophy
                    overlay.Parent = trophy
                    
                    -- Animation for appearing with a bounce effect using UIScale
                    local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                    local tween = TweenService:Create(uiScale, tweenInfo, {Scale = 1})
                    tween:Play()
                    
                    task.delay(0.5, function()
                        task.delay(0.2, function()
                            createStarburstEffect(overlay)
                        end)
                    end)
                end
            end)
        end
    end
end

-- Function to display the final results
--- Displays the results for a specific player.
--- @param playerScore table A table containing the result information for the player.
--- Expected structure:
--- {
---    drawing = ImageData, -- The drawing data to display.
---    score = number,      -- The score (0-10) to display as stars.
---    feedback = string    -- The feedback text to display.
--- }
local function displayResults(playerScore)
    assert(playerScore ~= nil, "Result data is nil")
    assert(playerScore.drawing ~= nil, "Result drawing is nil")
    assert(playerScore.score ~= nil, "Result score is nil")
    assert(playerScore.feedback ~= nil, "Result feedback is nil")
    assert(canvas ~= nil, "Canvas is nil for displaying results")
    assert(feedbackLabel ~= nil, "Feedback label is nil")
    assert(trophyContainer ~= nil, "Star container is nil")

    log("Displaying results...")

    -- Display the winning drawing
    displayDrawingData(canvas, playerScore.drawing)

    -- Show result UI once the image is loaded.
    resultScreen.Enabled = true

    -- Update the star rating
    updateStarDisplay(playerScore.score)

    -- Update the feedback text
    feedbackLabel.Text = playerScore.feedback
    feedbackLabel.Visible = true -- Ensure feedback label is visible
end


-- Function to initialize the result UI
--- Finds and initializes the necessary UI elements for the result screen,
--- including the canvas, star container, feedback label, and star images.
--- Creates the CanvasDraw instance. Prevents multiple initializations.
local function initResultUI()
    -- Prevent multiple initializations
    if resultUIInitialized then
        log("Result UI already initialized")
        return
    end

    resultUIInitialized = true
    log("Initializing Result UI")

    -- Get result screen
    resultScreen = PlayerGui:WaitForChild("ResultScreen") -- Renamed from VotingScreen
    assert(resultScreen ~= nil, "ResultScreen not found in PlayerGui")
    log("ResultScreen: ", resultScreen.Name)

    local topLevelContainer = resultScreen:WaitForChild("TopLevelContainer")
    local canvasContainer = topLevelContainer:WaitForChild("CanvasContainer")
    local canvasFrame = canvasContainer:WaitForChild("CanvasFrame")
    local trophyFrame = topLevelContainer:WaitForChild("TrophyFrame")

    -- Get references to result-specific UI elements
    trophyContainer = trophyFrame:WaitForChild("TrophyContainer")
    feedbackLabel = topLevelContainer:WaitForChild("FeedbackLabel")
    assert(trophyContainer ~= nil, "TrophyContainer not found in ResultScreen")
    assert(feedbackLabel ~= nil, "FeedbackLabel not found in ResultScreen")
    assert(feedbackLabel:IsA("TextLabel"), "FeedbackLabel must be a TextLabel")

    -- Populate stars table
    trophies = {}
    for i = 1, 10 do
        local trophy = trophyContainer:FindFirstChild("Trophy" .. i)
        assert(trophy ~= nil, "Trophy" .. i .. " not found in TrophyContainer")
        assert(trophy:IsA("Frame"), "Trophy" .. i .. " must be an Frame")
        table.insert(trophies, trophy:FindFirstChild("Trophy" .. i))
    end
    log("Found ", #trophies, " trophylabels.")

    -- Create a canvas for the drawing display
    if not canvas then -- Create canvas only if it doesn't exist
         canvas = CanvasDraw.new(canvasFrame, Vector2.new(math.ceil(canvasFrame.AbsoluteSize.X), math.ceil(canvasFrame.AbsoluteSize.Y)))
         log("Canvas: Created")
    else
         log("Canvas: Already exists")
    end
    assert(canvas ~= nil, "Failed to create or find canvas")
    log("Result UI initialized successfully")
end

-- Handle game state changes
--- Handles game state changes received from the server via GameStateChanged event.
--- Initializes UI if needed, shows/hides the screen based on game state,
--- and displays results when in RESULTS state.
--- @param stateData table Data containing the current game state and additional information.
Events.GameStateChanged.OnClientEvent:Connect(function(stateData)
    assert(stateData ~= nil, "ResultController: stateData is nil")
    log("ResultController: Game State Changed: ", stateData.state)


    if stateData.state == "RESULTS" then
        -- Ensure UI is initialized. Init upon the first call.
        if not resultUIInitialized then
            initResultUI()
        end
        assert(resultUIInitialized, "ResultUI is not initialized")
        -- Ensure UI is initialized (might have been initialized above or previously)
        if not resultUIInitialized then initResultUI() end
        assert(resultScreen ~= nil, "ResultScreen is nil when trying to display results")

        -- Check if we have results data
        if stateData.playerScores then
            -- Store the results data
            -- Display the results for current player
            displayResults(stateData.playerScores[tostring(LocalPlayer.UserId)])
        else
            warn("ResultController: Received RESULTS state but no resultsData was provided.")
            -- Display error message or hide elements
            if feedbackLabel then
                feedbackLabel.Text = "Results are unavailable."
                feedbackLabel.Visible = true
            else
                warn("ResultController: FeedbackLabel not found to display error.")
            end
            if trophyContainer then trophyContainer.Visible = false end
            if canvas then canvas:Clear() end
        end
    else
        -- Hide UI for other states (e.g., LOBBY, DRAWING)
        if resultScreen then
            resultScreen.Enabled = false
            log("ResultScreen disabled")
        end
        if canvas then canvas:Clear() end
    end
end)

log("ResultController script loaded") 