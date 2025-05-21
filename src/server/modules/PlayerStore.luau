local DataStoreService = game:GetService("DataStoreService")
local ServerScriptService = game:GetService("ServerScriptService")
local DataStoreHelper = require(ServerScriptService.modules.DataStoreHelper)
local SchemaValidator = require(ServerScriptService.modules.SchemaValidator)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = ReplicatedStorage:WaitForChild("Events")
local PlayerStore = {}
local PlayersDataStore = DataStoreService:GetDataStore("Players")
local MemoryStoreService   = game:GetService("MemoryStoreService")
local CacheMap             = MemoryStoreService:GetSortedMap("PlayerDataCache") --:contentReference[oaicite:2]{index=2}

local defaultMaximumGallerySize = 3
local defaultDrawingTTLAfterPlayerLeft = 3600
local defaultMaximumEnergy = 3
local energyRefreshInterval = 60 -- 12 * 60 * 60 -- 12 hours

-- Define schema for player data
local playerDataSchema = SchemaValidator.createSchema({
    Name = { type = "string", required = true },
    TotalPlayCount = { type = "number", required = true },
    TotalPoints = { type = "number", required = true },
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
    Energy: number,
    coins: number,
    maximumGallerySize: number,
    drawingTTLAfterPlayerLeft: number,  
    maximumEnergy: number,
    lastEnergyUpdate: number
}

-- tuning ----------------------------------------------------------------
local CACHE_TTL_SECONDS    = 30*60          -- 30 min cache
local LOCK_TTL_SECONDS     = 5              -- 5 s mutex
local LOCK_RETRIES         = 5
local LOCK_RETRY_DELAY     = 0.4
-------------------------------------------------------------------------

-- helpers ---------------------------------------------------------------
local function ckey(id: number) return "Player_"..id end
local function lkey(id: number) return "PlayerLock_"..id end
local function enc(t: any)   return t end
local function dec(s: any)   return s end
-------------------------------------------------------------------------

-- lock helper (atomic via UpdateAsync) ----------------------------------
local function acquireLock(id: number)
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
function PlayerStore:getPlayer(player: Player)
    assert(player,"Missing player")
    local id  = player.UserId
    local key = ckey(id)
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
            warn("Failed to get player data for " .. player.Name)
            return nil, data
        end
    end

    -- 3) default + healing if first visit
    if not data then
        data = {
            Name                      = player.Name,
            TotalPlayCount            = 0,
            TotalPoints               = 0,
            Energy                    = defaultMaximumEnergy,
            coins                     = 0,
            maximumGallerySize        = defaultMaximumGallerySize,
            drawingTTLAfterPlayerLeft = defaultDrawingTTLAfterPlayerLeft,
            maximumEnergy             = defaultMaximumEnergy,
            lastEnergyUpdate          = os.time(),
        }
    else
        data.maximumGallerySize        = data.maximumGallerySize or defaultMaximumGallerySize
        data.drawingTTLAfterPlayerLeft = data.drawingTTLAfterPlayerLeft or defaultDrawingTTLAfterPlayerLeft
        data.maximumEnergy             = data.maximumEnergy or defaultMaximumEnergy
        data.lastEnergyUpdate          = data.lastEnergyUpdate or os.time()
        data.coins                     = data.coins or 0

        if data.Energy > data.maximumEnergy then
            data.Energy = data.maximumEnergy
        end

        if os.time() - data.lastEnergyUpdate > energyRefreshInterval then
            data.Energy         = defaultMaximumEnergy
            data.lastEnergyUpdate = os.time()
        end

        self:savePlayer(player, data)
    end

    -- 4) validate
    local valid, errs = playerDataSchema:validate(data)
    if not valid then
        warn(("PlayerStore: invalid schema for %d: %s"):format(id, enc(errs)))
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
function PlayerStore:savePlayer(player: Player, data: PlayerData)
    assert(player, "Missing player")
    assert(data,   "Missing playerData")
    local id  = player.UserId
    local key = ckey(id)

    -- schema validation
    local valid, errs = playerDataSchema:validate(data)
    if not valid then
        warn(("PlayerStore: invalid schema for %d: %s"):format(id, enc(errs)))
        return false, "Invalid player data schema"
    end

    -- distributed mutex - optimistically acquire lock
    if not acquireLock(id) then
        warn("Could not acquire player write lock for " .. player.Name)
    end

    -- write-through: DataStore first (durable)
    local ok, err = DataStoreHelper:_performDataStoreOperationWithRetry(
        PlayersDataStore, "SetAsync", key, data
    )
    if not ok then
        warn(("PlayerStore: failed to save %d: %s"):format(id, tostring(err)))
        return false, "Failed to save: " .. tostring(err)
    end

    -- update cache
    pcall(function()
        CacheMap:SetAsync(key, enc(data), CACHE_TTL_SECONDS)
        CacheMap:RemoveAsync(lkey(id)) 
    end)

    -- Send the updated player data to the client.
    Events.PlayerDataUpdated:FireClient(player, data)

    return true, nil
end

return PlayerStore
