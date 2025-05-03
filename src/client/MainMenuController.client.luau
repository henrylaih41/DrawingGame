local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Utils = Modules:WaitForChild("Utils")
local ButtonEffects = require(Utils:WaitForChild("ButtonEffects"))
local Players= game:GetService("Players")
local ThemeList = require(ReplicatedStorage.Modules.GameData.ThemeList)
local CanvasDraw = require(ReplicatedStorage.Modules.Canvas.CanvasDraw)
local CanvasDisplay = require(ReplicatedStorage.Modules.Canvas.CanvasDisplay)

-- Get references to UI elements
local PlayerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
local MainMenuScreen = PlayerGui:WaitForChild("MainMenuScreen")
local TopLevelContainer = MainMenuScreen:WaitForChild("TopLevelContainer")
local BestScores = TopLevelContainer:WaitForChild("BestScores")
local Buttons = TopLevelContainer:WaitForChild("Buttons")
local SinglePlayerButton = Buttons:WaitForChild("SinglePlayerButton")
local BestScoresButton = Buttons:WaitForChild("BestScoresButton")
local BestScoreContainer = ReplicatedStorage:WaitForChild("UI"):WaitForChild("BestScoreContainer")

-- Set up events
local Events = ReplicatedStorage:WaitForChild("Events")
local StartGameEvent = Events:WaitForChild("StartGame")
local GameStateChangedEvent = Events:WaitForChild("GameStateChanged")
local RequestBestDrawingsEvent = Events:WaitForChild("RequestBestDrawings")
local ReceiveBestDrawingsEvent = Events:WaitForChild("ReceiveBestDrawings")
local ReceiveNewBestDrawingEvent = Events:WaitForChild("ReceiveNewBestDrawing")
local PlayerDataUpdatedEvent = Events:WaitForChild("PlayerDataUpdated")

-- Game state constants
local GameState = {
    MAIN_MENU = "MAIN_MENU",
    COUNTDOWN = "COUNTDOWN",
    DRAWING = "DRAWING",
    GRADING = "GRADING",
    VOTING = "VOTING",
    RESULTS = "RESULTS"
}

-- Store received drawings data
local bestDrawingsData = {}
local cleanupFunctions = {}
local bestScoresCanvasContainerByTheme = {}
-- Function to set up the Best-Scores scrolling frame completely in SCALE units
local function setupBestScoresUI()
    --------------------------------------------------
    -- 1. Create top bar for title and close button
    --------------------------------------------------
    local topBar = Instance.new("Frame")
    topBar.Name = "TopBar"
    topBar.Size = UDim2.new(1, 0, 0.1, 0)
    topBar.Position = UDim2.new(0, 0, 0, 0)
    topBar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    topBar.BorderSizePixel = 0
    topBar.ZIndex = 10
    topBar.Parent = BestScores
    
    -- Add title to top bar
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(0.8, 0, 0.8, 0)
    titleLabel.Position = UDim2.new(0.1, 0, 0.1, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.Text = "Best Drawings"
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.ZIndex = 11
    titleLabel.Parent = topBar
    
    -- Add close button to top bar
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0.08, 0, 0.8, 0)
    closeButton.Position = UDim2.new(1, 0, 0.1, 0)
    closeButton.AnchorPoint = Vector2.new(1, 0)
    closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeButton.BorderSizePixel = 0
    closeButton.Text = "X"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.GothamBold
    closeButton.ZIndex = 11
    
    -- Add corner rounding to the button
    local cornerRounding = Instance.new("UICorner")
    cornerRounding.CornerRadius = UDim.new(0.5, 0)
    cornerRounding.Parent = closeButton
    
    closeButton.MouseButton1Click:Connect(function()
        BestScores.Visible = false
    end)
    
    closeButton.Parent = topBar
    
    -- Add hover effect to the close button
    table.insert(cleanupFunctions, ButtonEffects.applyHoverEffects(closeButton, function()
        BestScores.Visible = false
    end))
    
    --------------------------------------------------
    -- 2.  Basic scrolling frame (now positioned below top bar)
    --------------------------------------------------
    local scoreScrollFrame = Instance.new("ScrollingFrame")
    scoreScrollFrame.Name = "ScoreScrollFrame"
    scoreScrollFrame.Size = UDim2.new(1, 0, 0.9, 0)
    scoreScrollFrame.Position = UDim2.new(0, 0, 0.1, 0)
    scoreScrollFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    scoreScrollFrame.BackgroundTransparency = 0.5
    scoreScrollFrame.BorderSizePixel = 0
    scoreScrollFrame.ScrollBarThickness = 6
    scoreScrollFrame.ScrollingDirection = Enum.ScrollingDirection.Y
    scoreScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y -- canvas grows for us
    scoreScrollFrame.Active = true

    scoreScrollFrame.Parent = BestScores
    
    --------------------------------------------------
    -- 3.  Layout maths (all in scale)
    --------------------------------------------------
    local template          = BestScoreContainer            -- keep original
    local itemsPerRow       = 3
    local paddingScale      = 0.01                          -- 2 % gap on both axes

    -- Width in scale for each cell after padding is removed.
    --  total horizontal padding = (itemsPerRow + 1) * paddingScale
    --  so usable width          = 1 - totalPadding
    local cellWidthScale    = (1 - paddingScale * (itemsPerRow + 1)) / itemsPerRow

    -- Derive an aspect ratio from the template so the height isn't zero
    local aspect            = 1                              -- fallback aspect
    if template.Size.X.Offset ~= 0 and template.Size.Y.Offset ~= 0 then
        aspect = template.Size.Y.Offset / template.Size.X.Offset
    elseif template.Size.X.Scale ~= 0 then
        aspect = template.Size.Y.Scale  / template.Size.X.Scale
    end

    local cellHeightOffset = cellWidthScale * scoreScrollFrame.AbsoluteSize.X

    --------------------------------------------------
    -- 4.  Grid layout that uses ONLY scale
    --------------------------------------------------
    local grid                  = Instance.new("UIGridLayout")
    grid.FillDirection          = Enum.FillDirection.Horizontal
    grid.SortOrder              = Enum.SortOrder.LayoutOrder
    grid.CellPadding            = UDim2.new(paddingScale, 0, paddingScale, 0)
    grid.CellSize               = UDim2.new(cellWidthScale, 0, 0, cellHeightOffset)
    grid.HorizontalAlignment    = Enum.HorizontalAlignment.Center
    grid.Parent                 = scoreScrollFrame

    --------------------------------------------------
    -- 5.  Create empty containers for each theme
    --------------------------------------------------
    for i, theme in ipairs(ThemeList) do
        local container = template:Clone()
        container.Name  = ("ThemeContainer_%s"):format(theme)
        -- Set the parent so we initialize this container faster.
        container.Parent = scoreScrollFrame

        local label = container:FindFirstChild("TopBar"):FindFirstChild("BestScoreTitle")
        if label then
            label.Text = theme
        end

        local arConstraint = Instance.new("UIAspectRatioConstraint")
        arConstraint.AspectRatio = aspect
        arConstraint.Parent      = container

        -- Wait for the container to be fully created
        while container.AbsoluteSize.X == 0 do
            task.wait(0.1)
        end

        local canvasFrame = container:FindFirstChild("CanvasFrame")
        local canvas = CanvasDraw.new(canvasFrame, Vector2.new(math.ceil(canvasFrame.AbsoluteSize.X), math.ceil(canvasFrame.AbsoluteSize.Y)))
        bestScoresCanvasContainerByTheme[theme] = {container = container, canvas = canvas}
    end

    return scoreScrollFrame
end

local function updateDrawingDisplayForTheme(drawingData, theme)
    local container = bestScoresCanvasContainerByTheme[theme].container
    local canvas = bestScoresCanvasContainerByTheme[theme].canvas

    -- Hide the loading
    local Loading = container:FindFirstChild("CanvasFrame"):FindFirstChild("Loading")
    Loading.Visible = false

    -- Update the container with drawing data if available
    -- If there is no previous scores, the drawingData will be nil
    if drawingData and drawingData.imageData then
        -- 1. Fetch the containerFrames and other UI elements
        local trophyContainer = container:FindFirstChild("TrophyFrame"):FindFirstChild("TrophyContainer")
        -- 2. Display the drawing
        CanvasDisplay.displayDrawingData(canvas, drawingData.imageData)
        -- 3. Update the star rating
        CanvasDisplay.updateStarDisplay(trophyContainer, drawingData.score, false)
    end
end

-- Separate function to update the drawings displays when data is received
local function updateDrawingDisplaysForAllThemes()
    -- Update each theme container with its drawing data
    for i, theme in ipairs(ThemeList) do
        -- Get drawing data from our cached bestDrawingsData
        local drawingData = bestDrawingsData[theme]
        updateDrawingDisplayForTheme(drawingData, theme)
    end
end

-- Set up event handler for receiving the drawings
ReceiveBestDrawingsEvent.OnClientEvent:Connect(function(drawings)
    bestDrawingsData = drawings or {}
    -- Update the displays with the new data
    updateDrawingDisplaysForAllThemes()
end)

-- Set up event handler for receiving the new best drawing
ReceiveNewBestDrawingEvent.OnClientEvent:Connect(function(drawingData, theme)
    updateDrawingDisplayForTheme(drawingData, theme)
end)

-- Add this function to request best drawings from server
local function requestBestDrawings()
    print("Requesting best drawings from server")
    RequestBestDrawingsEvent:FireServer()
end

-- Function to handle BestScores button click
local function onBestScoresClicked()
    print("Best Scores selected")
    -- Toggle visibility of BestScores frame
    BestScores.Visible = not BestScores.Visible
end

-- Function to handle SinglePlayer button click
local function onSinglePlayerClicked()
    print("Single Player mode selected")
    -- Fire event to GameManager with game mode parameter
    StartGameEvent:FireServer("SinglePlayer")
end

-- Function to handle MultiPlayer button click
local function onMultiPlayerClicked()
    print("Multi-Player mode selected")
    -- Fire event to GameManager with game mode parameter
    StartGameEvent:FireServer("MultiPlayer")
end

-- Function to handle game state changes
local function onGameStateChanged(stateData)
    if stateData and stateData.state then
        print("Game state changed to:", stateData.state)
        
        -- Show main menu only when in MAIN_MENU state, hide otherwise
        if stateData.state == GameState.MAIN_MENU then
            TopLevelContainer.Visible = true
        else
            TopLevelContainer.Visible = false
        end
    end
end

-- Apply button effects and on click events
table.insert(cleanupFunctions, ButtonEffects.applyHoverEffects(SinglePlayerButton, onSinglePlayerClicked))
table.insert(cleanupFunctions, ButtonEffects.applyHoverEffects(BestScoresButton, onBestScoresClicked))
-- Need to get a better press image
-- table.insert(cleanupFunctions, ButtonEffects.applyButtonPressEffect(SinglePlayerButton, "rbxassetid://140453037167378"))

-- Connect game state event
GameStateChangedEvent.OnClientEvent:Connect(onGameStateChanged)

local function onPlayerDataUpdated(playerData)
    print("Player data updated:", playerData)
    local count = Buttons.TrophyCount.count
    count.Text = tostring(playerData.TotalPoints)
end

PlayerDataUpdatedEvent.OnClientEvent:Connect(onPlayerDataUpdated)

-- Initialize the controller
local function initialize()
    local LocalPlayer = Players.LocalPlayer
    local pModule = require(LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
    local playerControls = pModule:GetControls()
    playerControls:Disable()
    
    -- First setup the UI structure
    setupBestScoresUI()
    
    -- Then request best drawings data from server
    requestBestDrawings()
    
    -- Initially hide the BestScores frame until button is clicked
    BestScores.Visible = false
    
    print("MainMenuController initialized")
end

-- Cleanup function for when this controller is no longer needed
local function cleanup()
    for _, cleanupFunc in ipairs(cleanupFunctions) do
        cleanupFunc()
    end
    
    -- Disconnect game state event if we stored the connection
    -- If we did store it, we would disconnect it here
end

initialize()

-- Return cleanup function if needed by a parent system
return cleanup 