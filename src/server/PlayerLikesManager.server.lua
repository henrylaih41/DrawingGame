local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStates = require(ServerScriptService.modules.ServerStates)
local PlayerStore = require(ServerScriptService.modules.PlayerStore)
local Events = ReplicatedStorage:WaitForChild("Events")

-- TODO: Make this configurable in a central server-side config file.
local FLUSH_INTERVAL = 1

-- We store the likes to this cache and flush it to the database every x seconds.
local playerLikesCache = {}

Events.LikeDrawing.OnServerEvent:Connect(function(player, likedPlayerId, canvasId)
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
        local playerData = PlayerStore:getPlayer(playerId)
        playerData.TotalPoints = playerData.TotalPoints + likes
        PlayerStore:savePlayer(playerId, playerData)
        local player = ServerStates.PlayerIdToPlayerMap[playerId]

        -- Send the updated player data to the client if it is still in the server.
        if player then
            Events.PlayerDataUpdated:FireClient(player, playerData)
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

