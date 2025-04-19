--!native
-- ResultController.client.luau
-- Handles client-side result display UI and logic

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local DebugFlag = true
local DebugUtils = require(ReplicatedStorage.Modules.Services.DebugUtils)

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
local ShowResultsEvent  = Events:WaitForChild("ShowResults")

-- Result display variables
local resultData = nil
local resultScreen = nil
local resultUIInitialized = false
local canvas = nil
local starContainer = nil
local feedbackLabel = nil
local stars = {} -- Table to hold star ImageLabels

-- Asset IDs for stars (Replace with your actual asset IDs)
local BASIC_TROPHY_ASSET = "rbxassetid://71126668050522"
local NICE_TROPHY_ASSET = "rbxassetid://99220692640700"
local GOOD_TROPHY_ASSET = "rbxassetid://77325310084856"
local GREAT_TROPHY_ASSET = "rbxassetid://135071378763005"
local EMPTY_TROPHY_ASSET = "rbxassetid://106246721622576"

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

-- Function to update the star display based on score
--- Updates the star images (empty/filled) based on the provided score.
--- Handles potential issues with finding star ImageLabels.
--- @param score number The score (0-10) determining the number of filled stars.
local function updateStarDisplay(score)
    assert(type(score) == "number" and score >= 0 and score <= 10, "Score must be a number between 0 and 10" .. score)
    assert(starContainer ~= nil, "Star container is nil")

    if #stars ~= 10 then
        log("Warning: Expected 10 stars, found ", #stars, ". Attempting to repopulate.")
        -- Attempt to repopulate stars table if container exists
        stars = {}
        for i = 1, 10 do
            local star = starContainer:FindFirstChild("Star" .. i)
            if star and star:IsA("ImageLabel") then
                table.insert(stars, star)
            else
                 warn("ResultController: Star" .. i .. " not found or not an ImageLabel in StarContainer during update.")
            end
        end
        if #stars ~= 10 then
             warn("ResultController: Could not find all 10 star ImageLabels in StarContainer. Cannot update stars.")
             return -- Exit if stars are still not found correctly
        end
    end

    log("Updating star display for score: ", score)
    for i, starLabel in ipairs(stars) do
        if i <= score then
            -- Determine which filled asset to use based on the total score
            if i == 10 then
                starLabel.Image = GREAT_TROPHY_ASSET -- Special trophy for the 10th star at max score
            elseif i >= 7 then
                starLabel.Image = GOOD_TROPHY_ASSET -- Use NICE trophy for scores 7-9
            else -- Score is 1-6
                starLabel.Image = GREAT_TROPHY_ASSET -- Use BASIC trophy for scores 1-6
            end
        else
            -- Use empty string to clear the image for stars beyond the score
            starLabel.Image = EMPTY_TROPHY_ASSET
        end
    end
    starContainer.Visible = true -- Ensure container is visible when updated
end

-- Function to display the final results
--- Displays the results for a specific player.
--- @param resultData table A table containing the result information for the player.
--- Expected structure:
--- {
---    drawing = ImageData, -- The drawing data to display.
---    score = number,      -- The score (0-10) to display as stars.
---    feedback = string    -- The feedback text to display.
--- }
local function displayResults(resultData)
    assert(resultData ~= nil, "Result data is nil")
    assert(resultData.drawing ~= nil, "Result drawing is nil")
    assert(resultData.score ~= nil, "Result score is nil")
    assert(resultData.feedback ~= nil, "Result feedback is nil")
    assert(canvas ~= nil, "Canvas is nil for displaying results")
    assert(feedbackLabel ~= nil, "Feedback label is nil")
    assert(starContainer ~= nil, "Star container is nil")

    log("Displaying results...")

    -- Display the winning drawing
    displayDrawingData(canvas, resultData.drawing)

    -- Update the star rating
    updateStarDisplay(resultData.score)

    -- Update the feedback text
    feedbackLabel.Text = resultData.feedback
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

    local displayContainer = resultScreen:WaitForChild("DrawingDisplayContainer")
    assert(displayContainer ~= nil, "DrawingDisplayContainer not found")
    log("DisplayContainer: ", displayContainer.Name)
    local displayFrame = displayContainer:WaitForChild("DrawingDisplay")
    assert(displayFrame ~= nil, "DrawingDisplay not found")
    log("DisplayFrame: ", displayFrame.Name)

    -- Get references to result-specific UI elements
    starContainer = resultScreen:WaitForChild("StarContainer")
    feedbackLabel = resultScreen:WaitForChild("FeedbackLabel")
    assert(starContainer ~= nil, "StarContainer not found in ResultScreen")
    assert(feedbackLabel ~= nil, "FeedbackLabel not found in ResultScreen")
    assert(feedbackLabel:IsA("TextLabel"), "FeedbackLabel must be a TextLabel")

    -- Populate stars table
    stars = {}
    for i = 1, 10 do
        local star = starContainer:FindFirstChild("Star" .. i)
        assert(star ~= nil, "Star" .. i .. " not found in StarContainer")
        assert(star:IsA("ImageLabel"), "Star" .. i .. " must be an ImageLabel")
        table.insert(stars, star)
    end
    log("Found ", #stars, " star labels.")
    log("DisplayFrame Size: ", displayFrame.AbsoluteSize.X, " ", displayFrame.AbsoluteSize.Y)

    -- Create a canvas for the drawing display
    if not canvas then -- Create canvas only if it doesn't exist
         canvas = CanvasDraw.new(displayFrame, Vector2.new(math.ceil(displayFrame.AbsoluteSize.X), math.ceil(displayFrame.AbsoluteSize.Y)))
         log("Canvas: Created")
    else
         log("Canvas: Already exists")
    end
    assert(canvas ~= nil, "Failed to create or find canvas")
    log("Result UI initialized successfully")
end

-- Handle game state changes
--- Handles messages received from the server via ShowResultsEvent.
--- Initializes UI if needed, stores data, shows/hides the screen,
--- and triggers result display based on message action ("Data", "Show", "Hide").
--- @param message table The message from the server, containing Action and optional Data.
ShowResultsEvent.OnClientEvent:Connect(function(message) -- Still needs resultData for RESULT state
    assert(message ~= nil, "ResultController: Message is nil")
    log("ResultController: Message: ", message.Action)

    -- Ensure UI is initialized. Init upon the first call.
    if not resultUIInitialized then
        initResultUI()
    end

    if message.Action == "Data" then
        assert(message.Data ~= nil, "ResultController: Message.Data is nil")
        log("ResultController: Received DATA message")
        log(message.Data)
        resultData = message.Data
    end

    if message.Action == "Show" then
        assert(resultUIInitialized, "ResultUI is not initialized")
        -- Ensure UI is initialized (might have been initialized above or previously)
        if not resultUIInitialized then initResultUI() end
        assert(resultScreen ~= nil, "ResultScreen is nil when trying to display results")

        -- Show result UI
        resultScreen.Enabled = true

        -- Display the results using the provided data
        if resultData then
            displayResults(resultData[tostring(LocalPlayer.UserId)])
        else
            warn("ResultController: Received RESULT state but no resultData was provided.")
            -- Display error message or hide elements
            if feedbackLabel then
                 feedbackLabel.Text = "Results are unavailable."
                 feedbackLabel.Visible = true
            else
                 warn("ResultController: FeedbackLabel not found to display error.")
            end
            if starContainer then starContainer.Visible = false end
            if canvas then canvas:Clear() end
        end
    end

    if message.Action == "Hide" then
        -- Hide UI for other states (e.g., LOBBY, DRAWING)
        if resultScreen then
            resultScreen.Enabled = false
            log("ResultScreen disabled")
        end
        canvas:Clear()
    end
end)

log("ResultController script loaded") 