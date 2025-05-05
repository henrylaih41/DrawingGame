local DataStoreService = game:GetService("DataStoreService")
local ServerScriptService = game:GetService("ServerScriptService")
local DataStoreHelper = require(ServerScriptService.modules.DataStoreHelper)
local SchemaValidator = require(ServerScriptService.modules.SchemaValidator)

local PlayerStore = {}
local PlayersDataStore = DataStoreService:GetDataStore("Players")

-- Define schema for player data
local playerDataSchema = SchemaValidator.createSchema({
    Name = { type = "string", required = true },
    TotalPlayCount = { type = "number", required = true },
    TotalPoints = { type = "number", required = true },
    Energy = { type = "number", required = true },
    coins = { type = "number", required = true },
    topPlaysWithoutImage = { type = "table", required = false}
})

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
            Energy = 10, -- Starting energy
            coins = 0
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
