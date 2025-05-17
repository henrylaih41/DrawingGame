local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConstants = require(ReplicatedStorage.Modules.GameData.GameConstants)
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Utils = Modules:WaitForChild("Utils")
local ButtonEffects = require(Utils:WaitForChild("ButtonEffects"))
local Players= game:GetService("Players")

-- Get references to UI elements
local PlayerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
local MainMenuScreen = PlayerGui:WaitForChild("MainMenuScreen")
local RankingScreen = PlayerGui:WaitForChild("RankingScreen")
local RankingScreenTopLevelContainer = RankingScreen:WaitForChild("TopLevelContainer")
local TopLevelContainer = MainMenuScreen:WaitForChild("TopLevelContainer")
local FeedbackContainer = TopLevelContainer:WaitForChild("FeedbackContainer")
local Buttons = TopLevelContainer:WaitForChild("Buttons")
local TrophyCount = TopLevelContainer:WaitForChild("TrophyCount")
local CoinFrame = TopLevelContainer:WaitForChild("CoinFrame")
local PencilFrame = TopLevelContainer:WaitForChild("PencilFrame")
local FeedbackButton = Buttons:WaitForChild("FeedbackButton")
local RankingButton = Buttons:WaitForChild("RankingButton")
local GalleryButton = Buttons:WaitForChild("GalleryButton")
local UiToggleButton = Buttons:WaitForChild("UiToggleButton")
local FeedbackCancelButton = FeedbackContainer:WaitForChild("CancelButton")
local FeedbackSubmitButton = FeedbackContainer:WaitForChild("SubmitButton")

-- Add a variable to track last submission time
local lastFeedbackSubmission = 0
local FEEDBACK_COOLDOWN = 5 -- 5 seconds cooldown
local showUI = true

local ui_on_image = "rbxassetid://122331809041801"
local ui_off_image = "rbxassetid://122240681959714"
local toggle_objects = {
    FeedbackButton,
    GalleryButton,
    RankingButton,
    TrophyCount,
    CoinFrame,
    PencilFrame
}
-- Set up events
local Events = ReplicatedStorage:WaitForChild("Events")
local GameStateChangedEvent = Events:WaitForChild("GameStateChanged")
local PlayerDataUpdatedEvent = Events:WaitForChild("PlayerDataUpdated")

-- Game state constants
local GameState = {
    MAIN_MENU = "MAIN_MENU",
    COUNTDOWN = "COUNTDOWN",
    DRAWING = GameConstants.PlayerStateEnum.DRAWING,
    GRADING = GameConstants.PlayerStateEnum.GRADING,
    VOTING = "VOTING",
    RESULTS = GameConstants.PlayerStateEnum.RESULTS
}

-- Store received drawings data
local cleanupFunctions = {}

local function onRankingClicked()
    RankingScreenTopLevelContainer.Visible = not RankingScreenTopLevelContainer.Visible
    if RankingScreenTopLevelContainer.Visible then
        RankingScreen.Enabled = true
    else
        RankingScreen.Enabled = false
    end
end

local function onGalleryClicked()
    -- GalleryScreen.Enabled = not GalleryScreen.Enabled
end

local function onUiToggleClicked()
    showUI = not showUI
    if showUI then
        UiToggleButton.Image = ui_on_image
        for _, object in ipairs(toggle_objects) do
            object.Visible = true
        end
    else
        UiToggleButton.Image = ui_off_image
        for _, object in ipairs(toggle_objects) do
            object.Visible = false
        end
    end
end

local theme_uuids = {}

Events.ReceiveThemeListPage.OnClientEvent:Connect(function(themeList)
    for _, theme in ipairs(themeList) do
        table.insert(theme_uuids, theme.value.uuid)
    end
end)

local function onFeedbackClicked()
    FeedbackContainer.Visible = true
end

local function onFeedbackCancelClicked()
    FeedbackContainer.Visible = false
end

local function onFeedbackSubmitClicked()
    -- Check if enough time has passed since last submission
    local currentTime = os.time()
    if currentTime - lastFeedbackSubmission < FEEDBACK_COOLDOWN then
        return -- Silently ignore repeat submissions during cooldown
    end
    
    -- Update last submission time
    lastFeedbackSubmission = currentTime
    
    local TextBox = FeedbackContainer:FindFirstChild("TextBox")
    if TextBox then
        Events.SendFeedback:FireServer(TextBox.Text)
    end
    local SubmitNotification = FeedbackContainer:FindFirstChild("SubmitNotification")
    if SubmitNotification then
        SubmitNotification.Visible = true
    end

    task.delay(3, function()
        SubmitNotification.Visible = false
    end)
end 

-- Function to handle game state changes
local function onGameStateChanged(stateData)
    if stateData and stateData.state then
        print("Game state changed to:", stateData.state)
        
        -- Show main menu only when in MAIN_MENU state, hide otherwise
        if stateData.state == GameConstants.PlayerStateEnum.IDLE then
            MainMenuScreen.Enabled = true
            TopLevelContainer.Visible = true
        else
            MainMenuScreen.Enabled = false
            TopLevelContainer.Visible = false
        end
    end
end

-- Apply button effects and on click events
table.insert(cleanupFunctions, ButtonEffects.applyHoverEffects(RankingButton, onRankingClicked))
table.insert(cleanupFunctions, ButtonEffects.applyHoverEffects(FeedbackButton, onFeedbackClicked))
table.insert(cleanupFunctions, ButtonEffects.applyHoverEffects(FeedbackCancelButton, onFeedbackCancelClicked))
table.insert(cleanupFunctions, ButtonEffects.applyHoverEffects(FeedbackSubmitButton, onFeedbackSubmitClicked))
table.insert(cleanupFunctions, ButtonEffects.applyHoverEffects(GalleryButton, onGalleryClicked))
table.insert(cleanupFunctions, ButtonEffects.applyHoverEffects(UiToggleButton, onUiToggleClicked))
-- Need to get a better press image
-- table.insert(cleanupFunctions, ButtonEffects.applyButtonPressEffect(SinglePlayerButton, "rbxassetid://140453037167378"))

-- Connect game state event
GameStateChangedEvent.OnClientEvent:Connect(onGameStateChanged)

local function onPlayerDataUpdated(playerData)
    local count = TrophyCount.count
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