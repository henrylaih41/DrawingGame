local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Utils = Modules:WaitForChild("Utils")
local ButtonEffects = require(Utils:WaitForChild("ButtonEffects"))
local Players= game:GetService("Players")
local TopPlaysCanvas = require(Utils:WaitForChild("TopPlaysCanvas"))
local GameConfig = require(ReplicatedStorage.Modules.GameData.GameConfig)

-- Get references to UI elements
local PlayerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
local MainMenuScreen = PlayerGui:WaitForChild("MainMenuScreen")
local ThemeListScreen = PlayerGui:WaitForChild("ThemeListScreen")
local RankingScreen = PlayerGui:WaitForChild("RankingScreen")
local RankingScreenTopLevelContainer = RankingScreen:WaitForChild("TopLevelContainer")
local TopLevelContainer = MainMenuScreen:WaitForChild("TopLevelContainer")
local BestScores = TopLevelContainer:WaitForChild("BestScores")
local Buttons = TopLevelContainer:WaitForChild("Buttons")
local SinglePlayerButton = Buttons:WaitForChild("SinglePlayerButton")
local BestScoresButton = Buttons:WaitForChild("BestScoresButton")
local RankingButton = Buttons:WaitForChild("RankingButton")

-- Set up events
local Events = ReplicatedStorage:WaitForChild("Events")
local StartGameEvent = Events:WaitForChild("StartGame")
local GameStateChangedEvent = Events:WaitForChild("GameStateChanged")
local RequestTopPlaysEvent = Events:WaitForChild("RequestTopPlays")
local ReceiveTopPlaysEvent = Events:WaitForChild("ReceiveTopPlays")
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
local cleanupFunctions = {}
local selfTopPlaysContainers = {}


-- Set up event handler for receiving the drawings
ReceiveTopPlaysEvent.OnClientEvent:Connect(function(topPlayUserId, topPlays)
    -- Only update the top plays if it is the local players top plays.
    if tostring(topPlayUserId) ~= tostring(Players.LocalPlayer.UserId) then
        return
    end

    for i = 1, GameConfig.TOP_PLAYS_LIMIT do
        local drawingData = topPlays[i]
        TopPlaysCanvas.updateDrawingDisplayForRank(drawingData, i, selfTopPlaysContainers)
    end
end)

-- Add this function to request best drawings from server
local function requestTopPlays()
    RequestTopPlaysEvent:FireServer(Players.LocalPlayer.UserId)
end

-- Function to handle BestScores button click
local function onBestScoresClicked()
    -- Toggle visibility of BestScores frame
    BestScores.Visible = not BestScores.Visible
end

local function onRankingClicked()
    RankingScreenTopLevelContainer.Visible = not RankingScreenTopLevelContainer.Visible
    if RankingScreenTopLevelContainer.Visible then
        RankingScreen.Enabled = true
    else
        RankingScreen.Enabled = false
    end
end

local theme_uuids = {}

Events.ReceiveThemeListPage.OnClientEvent:Connect(function(themeList)
    for _, theme in ipairs(themeList) do
        table.insert(theme_uuids, theme.value.uuid)
    end
end)

-- Function to handle SinglePlayer button click
local function onStartClicked()
    if #theme_uuids == 0 then
        warn("No themes found")
        return
    end

    -- Select a random theme from the list
    local randomIndex = math.random(1, #theme_uuids)
    local theme_uuid = theme_uuids[randomIndex]
    StartGameEvent:FireServer(theme_uuid)
    -- local ThemeListTopLevelContainer = ThemeListScreen:WaitForChild("TopLevelContainer")
    -- ThemeListTopLevelContainer.Visible = true 
end

-- Function to handle game state changes
local function onGameStateChanged(stateData)
    if stateData and stateData.state then
        print("Game state changed to:", stateData.state)
        
        -- Show main menu only when in MAIN_MENU state, hide otherwise
        if stateData.state == GameState.MAIN_MENU then
            MainMenuScreen.Enabled = true
            TopLevelContainer.Visible = true
        else
            MainMenuScreen.Enabled = false
            TopLevelContainer.Visible = false
        end
    end
end

-- Apply button effects and on click events
table.insert(cleanupFunctions, ButtonEffects.applyHoverEffects(SinglePlayerButton, onStartClicked))
table.insert(cleanupFunctions, ButtonEffects.applyHoverEffects(BestScoresButton, onBestScoresClicked))
table.insert(cleanupFunctions, ButtonEffects.applyHoverEffects(RankingButton, onRankingClicked))
-- Need to get a better press image
-- table.insert(cleanupFunctions, ButtonEffects.applyButtonPressEffect(SinglePlayerButton, "rbxassetid://140453037167378"))

-- Connect game state event
GameStateChangedEvent.OnClientEvent:Connect(onGameStateChanged)

local function onPlayerDataUpdated(playerData)
    local count = Buttons.TrophyCount.count
    if playerData then
        count.Text = tostring(playerData.TotalPoints)
    else
        warn("Player data is nil")
    end
end

PlayerDataUpdatedEvent.OnClientEvent:Connect(onPlayerDataUpdated)

-- Initialize the controller
local function initialize()
    math.randomseed(os.time())
    local LocalPlayer = Players.LocalPlayer
    local pModule = require(LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
    local playerControls = pModule:GetControls()
    playerControls:Disable()
    
    -- First setup the UI structure
    TopPlaysCanvas.setupTopPlaysCanvas(BestScores, selfTopPlaysContainers)
    
    -- Then request best drawings data from server
    requestTopPlays()
    
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

-- Check for Admin
if Players.LocalPlayer.UserId == 8240890430 then
    local LoadTheme = TopLevelContainer:WaitForChild("LoadTheme")
    local UpdateLeaderBoard = TopLevelContainer:WaitForChild("UpdateLeaderBoard")
    local TrimTopPoints = TopLevelContainer:WaitForChild("TrimTopPoints")
    local TestButton = TopLevelContainer:WaitForChild("TestButton")

    LoadTheme.Visible = true
    LoadTheme.MouseButton1Click:Connect(function()
        warn("Loading theme")
        Events.AdminCommand:FireServer("LoadTheme")
    end)

    UpdateLeaderBoard.Visible = true
    UpdateLeaderBoard.MouseButton1Click:Connect(function()
        warn("Updating leaderboard")
        Events.AdminCommand:FireServer("UpdateTopPoints")
    end)
    
    TrimTopPoints.Visible = true
    TrimTopPoints.MouseButton1Click:Connect(function()
        warn("Trimming top visits")
        Events.AdminCommand:FireServer("TrimTopPoints")
    end)

    TestButton.Visible = true
    TestButton.MouseButton1Click:Connect(function()
        warn("Testing")
        Events.TestEvent:FireServer()
    end)


end

-- Return cleanup function if needed by a parent system
return cleanup 