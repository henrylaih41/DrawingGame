-- LiveLeaderboard.lua  •  Server-side
--------------------------------------------------------------------
-- SERVICES
--------------------------------------------------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local PlayerStore = require(ServerScriptService.modules.PlayerStore)
local LeaderboardService = require(ServerScriptService.modules.LeaderboardService)
local Events = ReplicatedStorage:WaitForChild("Events")

local updateLeaderboard = function(plr)
    local playerData = PlayerStore:getPlayer(tostring(plr.UserId), true)
    local points = playerData["TotalPoints"]
    -- hard code threshold for now
    if points > 40 then
        LeaderboardService.putInMap(tostring(plr.UserId), plr.Name, points)
    end
end
--------------------------------------------------------------------
game.Players.PlayerAdded:Connect(function(plr)
    -- simple debounce: one read per join
    task.spawn(updateLeaderboard, plr)
end)

game.Players.PlayerRemoving:Connect(function(plr)
    task.spawn(updateLeaderboard, plr)
end)

Events.RequestTopScores.OnServerEvent:Connect(function(player)
    local playerData = PlayerStore:getPlayer(tostring(player.UserId))
    local topScores = LeaderboardService.getCachedTopScores()
    Events.ReceiveTopScores:FireClient(player, topScores, playerData)
end)

LeaderboardService.init()

--------------------------------------------------------------------
return LeaderboardService
