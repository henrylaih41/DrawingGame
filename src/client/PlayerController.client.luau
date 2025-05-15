local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = ReplicatedStorage:WaitForChild("Events")
local LocalPlayer = game:GetService("Players").LocalPlayer
local PlayerModule = require(LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
local ClientState = require(LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("ClientState"))
local GameConstants = require(ReplicatedStorage.Modules.GameData.GameConstants)
local Controls = PlayerModule:GetControls()
local LoadingScreen = LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("LoadingScreen")

Events.GameStateChanged.OnClientEvent:Connect(function(stateData)
    -- Update the player state.
    warn("GameStateChanged", stateData)
    local newState = stateData.state
    ClientState.PlayerState = newState
    if newState ~= GameConstants.PlayerStateEnum.IDLE then
        Controls:Disable()
        LoadingScreen.Enabled = true
    else
        Controls:Enable()
        LoadingScreen.Enabled = false
    end
end)

