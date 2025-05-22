-- LiveLeaderboard.lua  •  Server-side
--------------------------------------------------------------------
-- CONFIG
--------------------------------------------------------------------
local TOP_MAP_NAME        = "TopPointsV2"     -- MemoryStore SortedMap
local KEY_TTL_SECONDS     = 7 * 24 * 3600     -- 7 days(auto-evicts idle entries)
local MAX_ROWS            = 100               -- hard cap
local CACHE_UPDATE_INTERVAL = 60 * 60

--------------------------------------------------------------------
-- SERVICES
--------------------------------------------------------------------
local MS  = game:GetService("MemoryStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local PlayerStore = require(ServerScriptService.modules.PlayerStore)
local Events = ReplicatedStorage:WaitForChild("Events")

local TopMap     = MS:GetSortedMap(TOP_MAP_NAME)

--------------------------------------------------------------------
-- PUBLIC API TABLE
--------------------------------------------------------------------
local LB = {}          -- module to return
local cachedTopScores = nil

LB.MAX_ROWS = MAX_ROWS
--------------------------------------------------------------------
-- INTERNAL UTILITIES
--------------------------------------------------------------------

local function packValue(userId, playerName, points)
    -- Anything you want to keep for the row can live in here
    return {
        uid   = userId,      -- just in case
        name  = playerName,  -- what you asked for
        points = points,       -- convenient to have the plain score too
        ts    = os.time()    -- optional: when this record was written
    }
end

local function makeSortKey(points)
    return points
end

local function putInMap(userIdStr, playerName, points)
    TopMap:SetAsync(
        userIdStr,                 -- key
        packValue(userIdStr, playerName, points),  -- VALUE (table)
        KEY_TTL_SECONDS,                  -- TTL
        makeSortKey(points)                -- SORT KEY → what the map uses to order rows
    )
end

--------------------------------------------------------------------
-- 3.  Hook on player join to ensure they appear if already qualified
--------------------------------------------------------------------
game.Players.PlayerAdded:Connect(function(plr)
    -- simple debounce: one read per join
    task.spawn(function()
        local playerData = PlayerStore:getPlayer(tostring(plr.UserId))
        local points = playerData["TotalPoints"]
        -- hard code threshold for now
        if points > 10 then
            putInMap(tostring(plr.UserId), plr.Name, points)
        end
    end)
end)

Events.RequestTopScores.OnServerEvent:Connect(function(player)
    local playerData = PlayerStore:getPlayer(tostring(player.UserId))
    local topScores = cachedTopScores

    -- If the cached data is not available, fetch it from the map.
    if topScores == nil then
        topScores = TopMap:GetRangeAsync(Enum.SortDirection.Descending, MAX_ROWS)
        cachedTopScores = topScores
    end

    Events.ReceiveTopScores:FireClient(player, topScores, playerData)
end)

-- Spawn a task that updates the cached data every x seconds.
task.spawn(function()
    while true do
        task.wait(CACHE_UPDATE_INTERVAL)
        cachedTopScores = TopMap:GetRangeAsync(Enum.SortDirection.Descending, MAX_ROWS)
    end
end)

--------------------------------------------------------------------
return LB