local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Events = ReplicatedStorage:WaitForChild("Events")
local PlayerStore = require(ServerScriptService.modules.PlayerStore)
local ServerStates = require(ServerScriptService.modules.ServerStates)

local dependencies = {
    Events = Events,
    PlayerStore = PlayerStore,
    ServerStates = ServerStates,
}

local PlayerDataService = {}

function PlayerDataService._override(deps)
    for k, v in pairs(deps) do
        dependencies[k] = v
    end
end

function PlayerDataService.getDifficultyMultiplier(difficulty: string)
    if difficulty == "Easy" then
        return 1
    elseif difficulty == "Medium" then
        return 2
    elseif difficulty == "Hard" then
        return 3
    else
        warn("Unknown difficulty: " .. difficulty)
        return 1
    end
end

function PlayerDataService.getPlayerData(player: Player)
    local playerData = dependencies.ServerStates.PlayerState[player].playerData
    local errorMessage = nil

    if not playerData then
        playerData, errorMessage = dependencies.PlayerStore:getPlayer(player)
        if not playerData then
            error("Failed to get player data for " .. player.Name .. ": " .. tostring(errorMessage))
        end
    end

    return playerData
end

function PlayerDataService.savePlayerData(player: Player, playerData)
    if playerData then
        local playerState = dependencies.ServerStates.PlayerState[player]
        playerState.playerData = playerData
        dependencies.Events.PlayerDataUpdated:FireClient(player, playerData)
    end
end

function PlayerDataService.flushPlayerData(player: Player)
    local playerData = dependencies.ServerStates.PlayerState[player].playerData
    if playerData then
        dependencies.PlayerStore:savePlayer(player, playerData)
    end
end

return PlayerDataService

