--------------------------------------------------------------------
-- LeaderboardService.luau  •  Server-side module
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
local MemoryStoreService = game:GetService("MemoryStoreService")
local ServerScriptService = game:GetService("ServerScriptService")
local PlayerStore = require(ServerScriptService.modules.PlayerStore)

local TopMap = MemoryStoreService:GetSortedMap(TOP_MAP_NAME)

--------------------------------------------------------------------
-- PUBLIC API TABLE
--------------------------------------------------------------------
local LeaderboardService = {}          -- module to return
local cachedTopScores = nil

LeaderboardService.MAX_ROWS = MAX_ROWS

--- Returns the cached list of top scores. The cache will be populated from the
--  MemoryStore on first request.
function LeaderboardService.getCachedTopScores()
    if cachedTopScores == nil then
        cachedTopScores = TopMap:GetRangeAsync(Enum.SortDirection.Descending, MAX_ROWS)
    end
    return cachedTopScores
end

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

function LeaderboardService.putInMap(userIdStr, playerName, points)
    TopMap:SetAsync(
        userIdStr,                 -- key
        packValue(userIdStr, playerName, points),  -- VALUE (table)
        KEY_TTL_SECONDS,                  -- TTL
        makeSortKey(points)                -- SORT KEY → what the map uses to order rows
    )
end

-- Function to update the cached scores
function LeaderboardService.updateCachedScores()
    cachedTopScores = TopMap:GetRangeAsync(Enum.SortDirection.Descending, MAX_ROWS)
end

-- Function to initialize the service
function LeaderboardService.init()
    -- Spawn a task that updates the cached data every x seconds.
    task.spawn(function()
        while true do
            task.wait(CACHE_UPDATE_INTERVAL)
            LeaderboardService.updateCachedScores()
        end
    end)
end

return LeaderboardService
