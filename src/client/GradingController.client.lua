-- GradingController.client.lua
-- Controls the grading screen UI during the grading phase

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- References
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Events
local Events = ReplicatedStorage:WaitForChild("Events")
local GameStateChanged = Events:WaitForChild("GameStateChanged")
local GradingScreen = PlayerGui:WaitForChild("GradingScreen")
local topLevelContainer = GradingScreen:WaitForChild("TopLevelContainer")

-- Constants
local GameState = {
    LOBBY = "LOBBY",
    COUNTDOWN = "COUNTDOWN",
    DRAWING = "DRAWING",
    GRADING = "GRADING",
    VOTING = "VOTING",
    RESULTS = "RESULTS"
}

-- Function to handle game state changes
local function handleGameStateChanged(stateData)
    local state = stateData.state
    if state == GameState.GRADING then
        topLevelContainer.Visible = true
    else
        topLevelContainer.Visible = false
    end
end

-- Initialize
local function init()
    -- Set initial visibility
    topLevelContainer.Visible = false
    -- Connect to game state changes
    GameStateChanged.OnClientEvent:Connect(handleGameStateChanged)
    
    print("GradingController initialized")
end

init() 