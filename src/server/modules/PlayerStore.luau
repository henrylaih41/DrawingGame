local DataStoreService = game:GetService("DataStoreService")
local ServerScriptService = game:GetService("ServerScriptService")
local DataStoreHelper = require(ServerScriptService.modules.DataStoreHelper)
local SchemaValidator = require(ServerScriptService.modules.SchemaValidator)
local HttpService = game:GetService("HttpService")
local PlayerStore = {}
local PlayersDataStore = DataStoreService:GetDataStore("Players")

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

-- Player Data Management Functions
function PlayerStore:getPlayer(player)
    assert(player, "Missing player parameter")
    local playerId = player.UserId
    
    local success, result = DataStoreHelper:_performDataStoreOperationWithRetry(
        PlayersDataStore,
        "GetAsync",
        "Player_" .. playerId,
        nil,
        true
    )
    
    if success and result then
        -- Self healing.
        result.maximumGallerySize = result.maximumGallerySize or defaultMaximumGallerySize
        result.drawingTTLAfterPlayerLeft = result.drawingTTLAfterPlayerLeft or defaultDrawingTTLAfterPlayerLeft
        result.maximumEnergy = result.maximumEnergy or defaultMaximumEnergy
        result.lastEnergyUpdate = result.lastEnergyUpdate or os.time()
        result.coins = result.coins or 0

        -- Energy should never exceed the maximum energy.
        if result.Energy > result.maximumEnergy then
            result.Energy = result.maximumEnergy
        end

        -- Refresh the energy if it has been more than 12 hours since the last energy update.
        if os.time() - result.lastEnergyUpdate > energyRefreshInterval then
            result.Energy = defaultMaximumEnergy
            result.lastEnergyUpdate = os.time()
        end

        -- Validate the schema
        local valid, errors = playerDataSchema:validate(result)
        if not valid then
            warn("BackendService: Invalid player data schema for player " .. playerId .. ": " .. HttpService:JSONEncode(errors))
            return nil, "Invalid player data schema"
        end
        return result, nil
    else
        -- Create default player data if not found
        local defaultData = {
            Name = player.Name,
            TotalPlayCount = 0,
            TotalPoints = 0,
            Energy = defaultMaximumEnergy, -- Starting energy
            coins = 0,
            maximumGallerySize = defaultMaximumGallerySize,
            drawingTTLAfterPlayerLeft = defaultDrawingTTLAfterPlayerLeft,
            maximumEnergy = defaultMaximumEnergy,
            lastEnergyUpdate = os.time()
        }
        
        -- Try to save the default data
        local saveSuccess, saveError = self:savePlayer(player, defaultData)
        if not saveSuccess then
            return nil, "Failed to create player profile: " .. tostring(saveError)
        end
        
        return defaultData, nil
    end
end

function PlayerStore:savePlayer(player, playerData)
    assert(player, "Missing player parameter")
    assert(playerData, "Missing playerData parameter")
    print("Saving player data for " .. player.Name)
    local playerId = player.UserId
    
    -- Validate the schema
    local valid, errors = playerDataSchema:validate(playerData)
    if not valid then
        warn("BackendService: Invalid player data schema for player " .. playerId .. ": " .. HttpService:JSONEncode(errors))
        return false, "Invalid player data schema"
    end
    
    -- Save to DataStore with retry logic
    local success, error = DataStoreHelper:_performDataStoreOperationWithRetry(
        PlayersDataStore,
        "SetAsync",
        "Player_" .. playerId,
        playerData
    )
    
    if not success then
        warn("BackendService: Failed to save player data for " .. playerId .. ": " .. tostring(error))
        return false, "Failed to save player data: " .. tostring(error)
    end
    
    return true, nil
end

return PlayerStore
