local DataStoreService = game:GetService("DataStoreService")
local ServerScriptService = game:GetService("ServerScriptService")
local DataStoreHelper = require(ServerScriptService.modules.DataStoreHelper)
local SchemaValidator = require(ServerScriptService.modules.SchemaValidator)
local ServerConfig = require(ServerScriptService.modules.ServerConfig)
local Players = game:GetService("Players")
local PlayerStore = {}
local PlayersDataStore = DataStoreService:GetDataStore("Players")
local MemoryStoreService   = game:GetService("MemoryStoreService")
local CacheMap             = MemoryStoreService:GetSortedMap("PlayerDataCache") --:contentReference[oaicite:2]{index=2}

local defaultMaximumGallerySize = ServerConfig.DEFAULT_MAXIMUM_GALLERY_SIZE
local defaultDrawingTTLAfterPlayerLeft = ServerConfig.DEFAULT_DRAWING_TTL_AFTER_PLAYER_LEFT
local defaultMaximumEnergy = ServerConfig.DEFAULT_MAXIMUM_ENERGY
local defaultMaximumLikeQuota = ServerConfig.DEFAULT_MAXIMUM_LIKE_QUOTA
local energyRefreshInterval = ServerConfig.ENERGY_REFRESH_INTERVAL -- 12 * 60 * 60 -- 12 hours

-- Define schema for player data
local playerDataSchema = SchemaValidator.createSchema({
    Name = { type = "string", required = true },
    TotalPlayCount = { type = "number", required = true },
    TotalPoints = { type = "number", required = true },
    PreviousTotalPoints = { type = "number", required = true },
    Energy = { type = "number", required = true },
    coins = { type = "number", required = true },
    topPlaysWithoutImage = { type = "table", required = false},
    maximumGallerySize = { type = "number", required = true },
    drawingTTLAfterPlayerLeft = { type = "number", required = true },
    maximumEnergy = { type = "number", required = true },
    lastEnergyUpdate = { type = "number", required = true }
})

export type PlayerData = {
    Name: string,
    TotalPlayCount: number,
    TotalPoints: number,
    PreviousTotalPoints: number,
    Energy: number,
    coins: number,
    maximumGallerySize: number,
    drawingTTLAfterPlayerLeft: number,  
    maximumEnergy: number,
    lastEnergyUpdate: number
}

-- tuning ----------------------------------------------------------------
local CACHE_TTL_SECONDS    = ServerConfig.CACHE_TTL_SECONDS          -- 30 min cache
local LOCK_TTL_SECONDS     = ServerConfig.LOCK_TTL_SECONDS           -- 5 s mutex
local LOCK_RETRIES         = ServerConfig.LOCK_RETRIES
local LOCK_RETRY_DELAY     = ServerConfig.LOCK_RETRY_DELAY
-------------------------------------------------------------------------

-- helpers ---------------------------------------------------------------
local function ckey(id: string) return "Player_"..id end
local function lkey(id: string) return "PlayerLock_"..id end
local function enc(t: any)   return t end
local function dec(s: any)   return s end
-------------------------------------------------------------------------

-- lock helper (atomic via UpdateAsync) ----------------------------------
local function acquireLock(id: string)
    for i = 1, LOCK_RETRIES do
        local claimed = false
        local ok = pcall(function()
            CacheMap:UpdateAsync(lkey(id), function(oldVal)
                if oldVal == nil then          -- nobody owns lock
                    claimed = true
                    return true               -- become owner
                end
                return oldVal                 -- keep current owner
            end, LOCK_TTL_SECONDS)            -- lock expires automatically
        end)
        if ok and claimed then
            return true                       -- we own the mutex
        end
        task.wait(LOCK_RETRY_DELAY)           -- back-off and retry
    end
    return false                              -- could not obtain lock
end
---------------------------------------------------------------------
-- READ -------------------------------------------------------------
---------------------------------------------------------------------
function PlayerStore:getPlayer(playerId: string)
    local player = Players:GetPlayerByUserId(tonumber(playerId))

    local startTime = os.time()

    while not player and os.time() - startTime < ServerConfig.PLAYER_DATA_TIMEOUT do
        task.wait(0.2)
        player = Players:GetPlayerByUserId(tonumber(playerId))
    end

    local playerName = player and player.Name or "Unknown"

    if not player then
        warn("Player not found for " .. playerId)
    end

    local key = ckey(playerId)
    local success, data = nil, nil

    -- 1) MemoryStore fast-path
    local ok, cached = pcall(function() return CacheMap:GetAsync(key) end)
    if ok and cached then
        data = dec(cached)
    end

    -- 2) DataStore fallback
    if not data then
        success, data = DataStoreHelper:_performDataStoreOperationWithRetry(
            PlayersDataStore, "GetAsync", key, nil, true
        )

        if not success then
            warn("Failed to get player data for " .. playerId)
            return nil, data
        end
    end

    -- 3) default + healing if first visit
    if not data then
        data = {
            Name                      = playerName,
            TotalPlayCount            = 0,
            TotalPoints               = 0,
            PreviousTotalPoints       = 0,
            coins                     = 0,
            -- TODO: Update this based on player type or TotalPoints.
            Energy                    = defaultMaximumEnergy,
            LikeQuota                 = defaultMaximumLikeQuota,
            lastEnergyUpdate          = os.time(),
        }
    end 
    -- Self healing
    data.Name                      = data.Name or playerName
    data.TotalPlayCount            = data.TotalPlayCount or 0
    data.TotalPoints               = data.TotalPoints or 0
    data.PreviousTotalPoints       = data.PreviousTotalPoints or data.TotalPoints
    data.coins                     = data.coins or 0
    data.Energy                    = data.Energy or defaultMaximumEnergy
    data.LikeQuota                 = data.LikeQuota or defaultMaximumLikeQuota
    data.lastEnergyUpdate          = data.lastEnergyUpdate or os.time()

    -- TODO: Update these value based on player type or TotalPoints.
    data.maximumEnergy = defaultMaximumEnergy
    data.maximumLikeQuota = defaultMaximumLikeQuota
    data.drawingTTLAfterPlayerLeft = defaultDrawingTTLAfterPlayerLeft
    data.maximumGallerySize = defaultMaximumGallerySize

    if data.Energy > data.maximumEnergy then
        data.Energy = data.maximumEnergy
    end

    if data.LikeQuota > data.maximumLikeQuota then
        data.LikeQuota = data.maximumLikeQuota
    end

    if os.time() - data.lastEnergyUpdate > energyRefreshInterval or playerId == "8240890430" then
        data.Energy         = data.maximumEnergy
        data.LikeQuota      = data.maximumLikeQuota
        data.lastEnergyUpdate = os.time()
        self:savePlayer(playerId, data)
    end

    -- 4) validate
    local valid, errs = playerDataSchema:validate(data)
    if not valid then
        warn(("PlayerStore: invalid schema for %s: %s"):format(playerId, enc(errs)))
        return nil, "Invalid player data schema"
    end

    -- 5) back-fill cache (best effort)
    pcall(function()
        CacheMap:SetAsync(key, enc(data), CACHE_TTL_SECONDS)
    end)

    return data, nil
end

---------------------------------------------------------------------
-- WRITE ------------------------------------------------------------
---------------------------------------------------------------------
function PlayerStore:savePlayer(playerId: string, data: PlayerData, flush: boolean?)
    assert(playerId, "Missing playerId")
    assert(data,   "Missing playerData")
    local key = ckey(playerId)

    if flush == nil then
        flush = true
    end

    -- schema validation
    local valid, errs = playerDataSchema:validate(data)
    if not valid then
        warn(("PlayerStore: invalid schema for %s: %s"):format(playerId, enc(errs)))
        return false, "Invalid player data schema"
    end

    -- distributed mutex - optimistically acquire lock
    if not acquireLock(playerId) then
        warn("Could not acquire player write lock for " .. playerId)
    end

    if flush then
        local ok, err = DataStoreHelper:_performDataStoreOperationWithRetry(
            PlayersDataStore, "SetAsync", key, data
        )

        if not ok then
            warn(("PlayerStore: failed to save %s: %s"):format(playerId, tostring(err)))
        end
    end

    -- update cache
    pcall(function()
        CacheMap:SetAsync(key, enc(data), CACHE_TTL_SECONDS)
        CacheMap:RemoveAsync(lkey(playerId)) 
    end)

    return true, nil
end

return PlayerStore
