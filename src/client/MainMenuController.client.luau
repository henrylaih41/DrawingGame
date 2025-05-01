local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Utils = Modules:WaitForChild("Utils")
local ButtonEffects = require(Utils:WaitForChild("ButtonEffects"))
local Players= game:GetService("Players")
local ThemeList = require(ReplicatedStorage.Modules.GameData.ThemeList)

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

-- Game state constants
local GameState = {
    MAIN_MENU = "MAIN_MENU",
    COUNTDOWN = "COUNTDOWN",
    DRAWING = "DRAWING",
    GRADING = "GRADING",
    VOTING = "VOTING",
    RESULTS = "RESULTS"
}

-- Function to set up the Best-Scores scrolling frame completely in SCALE units
local function setupBestScoresScrollFrame()
    --------------------------------------------------
    -- 1.  Basic scrolling frame
    --------------------------------------------------
    local scoreScrollFrame            = Instance.new("ScrollingFrame")
    scoreScrollFrame.Name             = "ScoreScrollFrame"
    scoreScrollFrame.Size             = UDim2.new(1, 0, 1, 0)
    scoreScrollFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    scoreScrollFrame.BackgroundTransparency = 0.5
    scoreScrollFrame.BorderSizePixel  = 0
    scoreScrollFrame.ScrollBarThickness = 6
    scoreScrollFrame.ScrollingDirection = Enum.ScrollingDirection.Y
    scoreScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y -- canvas grows for us

    scoreScrollFrame.Parent           = BestScores              -- << your frame >>

    --------------------------------------------------
    -- 2.  Layout maths (all in scale)
    --------------------------------------------------
    local template          = BestScoreContainer            -- keep original
    local itemsPerRow       = 3
    local paddingScale      = 0.02                          -- 2 % gap on both axes

    -- Width in scale for each cell after padding is removed.
    --  total horizontal padding = (itemsPerRow + 1) * paddingScale
    --  so usable width          = 1 - totalPadding
    local cellWidthScale    = (1 - paddingScale * (itemsPerRow + 1)) / itemsPerRow

    -- Derive an aspect ratio from the template so the height isn’t zero
    local aspect            = 1                              -- fallback aspect
    if template.Size.X.Offset ~= 0 and template.Size.Y.Offset ~= 0 then
        aspect = template.Size.Y.Offset / template.Size.X.Offset
    elseif template.Size.X.Scale ~= 0 then
        aspect = template.Size.Y.Scale  / template.Size.X.Scale
    end
    local cellHeightScale   = cellWidthScale * aspect        -- non-zero!

    --------------------------------------------------
    -- 3.  Grid layout that uses ONLY scale
    --------------------------------------------------
    local grid                  = Instance.new("UIGridLayout")
    grid.FillDirection          = Enum.FillDirection.Horizontal
    grid.SortOrder              = Enum.SortOrder.LayoutOrder
    grid.CellPadding            = UDim2.new(paddingScale, 0, paddingScale, 0)
    grid.CellSize               = UDim2.new(cellWidthScale, 0, cellHeightScale, 0)
    grid.HorizontalAlignment    = Enum.HorizontalAlignment.Center
    grid.Parent                 = scoreScrollFrame

    --------------------------------------------------
    -- 4.  Populate the grid
    --------------------------------------------------
    for i, theme in ipairs(ThemeList) do
        local container = template:Clone()
        container.Name  = ("ThemeContainer_%s"):format(theme)

        local label = container:FindFirstChild("TopBar"):FindFirstChild("BestScoreTitle")
        if label then
            label.Text = theme
        end

        -- Optional: keep the template’s aspect in case someone resizes later
        local arConstraint = Instance.new("UIAspectRatioConstraint")
        arConstraint.AspectRatio = aspect
        arConstraint.Parent      = container

        container.Parent = scoreScrollFrame      -- grid handles positioning
    end

    return scoreScrollFrame
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
local cleanupFunctions = {}
table.insert(cleanupFunctions, ButtonEffects.applyHoverEffects(SinglePlayerButton, onSinglePlayerClicked))
table.insert(cleanupFunctions, ButtonEffects.applyHoverEffects(BestScoresButton, onBestScoresClicked))
-- Need to get a better press image
-- table.insert(cleanupFunctions, ButtonEffects.applyButtonPressEffect(SinglePlayerButton, "rbxassetid://140453037167378"))

-- Connect game state event
GameStateChangedEvent.OnClientEvent:Connect(onGameStateChanged)

-- Initialize the controller
local function initialize()
    local LocalPlayer = Players.LocalPlayer
    local pModule = require(LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
    local playerControls = pModule:GetControls()
    playerControls:Disable()
    
    -- Set up the best scores scroll frame
    setupBestScoresScrollFrame()
    
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