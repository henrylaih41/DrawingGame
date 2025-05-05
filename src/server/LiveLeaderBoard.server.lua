-- LiveLeaderboard.lua  •  Server-side
--------------------------------------------------------------------
-- CONFIG
--------------------------------------------------------------------
local TOP_MAP_NAME        = "TopPoints"     -- MemoryStore SortedMap
local KEY_TTL_SECONDS     = 30 * 24 * 3600     -- 30 days(auto-evicts idle entries)
local MAX_ROWS            = 100               -- hard cap
local OVERFLOW_FETCH      = MAX_ROWS + 1       -- grab one extra to trim

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
    -- Preserve your “higher score first, recent wins ties” rule
    --   score ⬆  ⇒ rank ⬆
    --   newer    ⇒ rank ⬆ on equal score
    return (points * 2^32) + (0xFFFFFFFF - os.time())
end

local function putInMap(userIdStr, playerName, points)
    TopMap:SetAsync(
        userIdStr,                 -- key
        packValue(userIdStr, playerName, points),  -- VALUE (table)
        KEY_TTL_SECONDS,                  -- TTL
        makeSortKey(points)                -- SORT KEY → what the map uses to order rows
    )
end

local function maybeTrim()
    -- ensure we never exceed 100 rows
    local page = TopMap:GetRangeAsync(Enum.SortDirection.Descending, OVERFLOW_FETCH)
    if #page > MAX_ROWS then
        local last = page[#page]       -- #101
        TopMap:RemoveAsync(last.key)
    end
end

--------------------------------------------------------------------
-- 2.  Main exposed function: add points & maintain leaderboard
--------------------------------------------------------------------
function LB.UpdatePlayerPoints(player, totalPoints: number)
    -- update the MemoryStore map (fast, quota-cheap)
    putInMap(tostring(player.UserId), player.Name, totalPoints)
    maybeTrim()
end

--------------------------------------------------------------------
-- 3.  Hook on player join to ensure they appear if already qualified
--------------------------------------------------------------------
game.Players.PlayerAdded:Connect(function(plr)
    -- simple debounce: one read per join
    task.spawn(function()
        local playerData = PlayerStore:getPlayer(plr)
        local points = playerData["TotalPoints"]

        -- fetch 100-th score once to compare (cheap)
        local page = TopMap:GetRangeAsync(Enum.SortDirection.Descending, MAX_ROWS) -- row #100
        local needsInsert = (#page < MAX_ROWS)
        if not needsInsert then
            local thresholdPoints = math.floor(page[1].value / 2^32)
            if points> thresholdPoints then
                needsInsert = true
            end
        end

        if needsInsert then
            putInMap(tostring(plr.UserId), plr.Name, points)
            maybeTrim()
        end
    end)
end)

Events.RequestTopScores.OnServerEvent:Connect(function(player)
    local playerData = PlayerStore:getPlayer(player)
    local topScores = TopMap:GetRangeAsync(Enum.SortDirection.Descending, MAX_ROWS)
    Events.ReceiveTopScores:FireClient(player, topScores, playerData)
end)

--------------------------------------------------------------------
return LB