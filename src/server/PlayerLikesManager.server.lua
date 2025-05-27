local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStates = require(ServerScriptService.modules.ServerStates)
local PlayerStore = require(ServerScriptService.modules.PlayerStore)
local Events = ReplicatedStorage:WaitForChild("Events")
local ServerConfig = require(ServerScriptService.modules.ServerConfig)

local FLUSH_INTERVAL = ServerConfig.LIKES.FLUSH_INTERVAL

-- We store the likes to this cache and flush it to the database every x seconds.
local playerLikesCache = {}

Events.LikeDrawing.OnServerEvent:Connect(function(player, likedPlayerId, canvasId)
    local playerData = PlayerStore:getPlayer(player.UserId)

    if playerData.LikeQuota <= 0 then
        Events.ShowNotification:FireClient(
            player, "You don't have any likes left! Likes are refilled every 12 hours!.", "red")
        return
    end

    playerData.LikeQuota = playerData.LikeQuota - 1

    PlayerStore:savePlayer(player.UserId, playerData)
    Events.PlayerDataUpdated:FireClient(player, {player = player, playerData = playerData})

    local playerLikes = playerLikesCache[likedPlayerId] or 0
    playerLikesCache[likedPlayerId] = playerLikes + 1

    local likedPlayer = ServerStates.PlayerIdToPlayerMap[likedPlayerId]

    if likedPlayer then
        Events.ShowNotification:FireClient(
            likedPlayer, ("Player %s liked your drawing!"):format(player.Name), "green")
    end
end)

local function flushPlayerLikesCache()

    for playerId, likes in pairs(playerLikesCache) do
        local playerData = PlayerStore:getPlayer(playerId, true)
        playerData.TotalPoints = playerData.TotalPoints + likes
        PlayerStore:savePlayer(playerId, playerData)
        local player = ServerStates.PlayerIdToPlayerMap[playerId]

        -- Send the updated player data to the client if it is still in the server.
        if player then
            Events.PlayerDataUpdated:FireAllClients({player = player, playerData = playerData})
        end
    end

    -- Clear the cache.
    playerLikesCache = {}
end

task.spawn(function()
    while true do
        task.wait(FLUSH_INTERVAL)
        flushPlayerLikesCache()
    end
end)

