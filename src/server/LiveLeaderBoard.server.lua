-- LiveLeaderboard.lua  •  Server-side
--------------------------------------------------------------------
-- SERVICES
--------------------------------------------------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local PlayerStore = require(ServerScriptService.modules.PlayerStore)
local LeaderboardService = require(ServerScriptService.modules.LeaderboardService)
local Events = ReplicatedStorage:WaitForChild("Events")

--------------------------------------------------------------------
--------------------------------------------------------------------
game.Players.PlayerAdded:Connect(function(plr)
    -- simple debounce: one read per join
    task.spawn(function()
        local playerData = PlayerStore:getPlayer(tostring(plr.UserId), plr.Name)
        local points = playerData["TotalPoints"]
        -- hard code threshold for now
        if points > 14 then
            LeaderboardService.putInMap(tostring(plr.UserId), plr.Name, points)
        end
    end)
end)

Events.RequestTopScores.OnServerEvent:Connect(function(player)
    local playerData = PlayerStore:getPlayer(tostring(player.UserId), player.Name)
    local topScores = LeaderboardService.getCachedTopScores()

    Events.ReceiveTopScores:FireClient(player, topScores, playerData)
end)

LeaderboardService.init()

--------------------------------------------------------------------
return LeaderboardService
