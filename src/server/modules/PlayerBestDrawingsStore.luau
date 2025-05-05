local DataStoreService = game:GetService("DataStoreService")
local ServerScriptService = game:GetService("ServerScriptService")
local DataStoreHelper = require(ServerScriptService.modules.DataStoreHelper)
local HttpService = game:GetService("HttpService")
local SchemaValidator = require(ServerScriptService.modules.SchemaValidator)
local PlayerBestDrawingsDataStore = DataStoreService:GetDataStore("PlayerBestDrawings")

local PlayerBestDrawingsStore = {}
local DEBUG_ENABLED = true

-- Debug print function that only outputs when debugging is enabled
local function debugPrint(message, ...)
    if DEBUG_ENABLED then
        print(string.format(message, ...))
    end
end

function PlayerBestDrawingsStore:generateDrawingKey(playerId, theme_uuid)
    return string.format("%d_%s", playerId, theme_uuid)
end

-- Define schema for image data
PlayerBestDrawingsStore.imageDataSchema = SchemaValidator.createSchema({
    ImageBuffer = { type = "string", required = true },
    Width = { type = "number", required = true },
    Height = { type = "number", required = true }
})

-- Define schema for best drawings
PlayerBestDrawingsStore.playerBestDrawingSchema = SchemaValidator.createSchema({
    imageData = { type = "table", required = true },
    score = { type = "number", required = true },
    points = { type = "number", required = true }, -- Added points field
    timestamp = { type = "number", required = true },
    theme = { type = "string", required = true },
    theme_uuid = { type = "string", required = true }, -- Added theme_uuid field
    playerId = { type = "number", required = true }
})

-- Function to get a player's drawing for a specific theme
function PlayerBestDrawingsStore:getPlayerBestDrawing(player, theme_uuid)
    assert(player, "Missing player parameter")
    assert(theme_uuid, "Missing theme parameter")
    
    -- Create a unique key for this player and theme combination
    local key = self:generateDrawingKey(player.UserId, theme_uuid)
    
    -- Attempt to get the drawing data from the DataStore
    local success, result = pcall(function()
        -- Use the utility function with retry for DataStore operation
        local success, drawingData = DataStoreHelper:_performDataStoreOperationWithRetry(
            PlayerBestDrawingsDataStore, 
            "GetAsync", 
            key,
            nil,
            true -- Enable retry
        )
        
        if not success then
            error("Failed to retrieve data: " .. tostring(drawingData))
        end
        
        -- Update size statistics if data was returned
        if drawingData then
            local dataSize = #HttpService:JSONEncode(drawingData)
            debugPrint("Read %d bytes from DataStore for key: %s", dataSize, key)
        end
        
        -- Validate the data if it exists
        if drawingData then
            local isValid, errorMessage = self.playerBestDrawingSchema:validate(drawingData)
            assert(isValid, "Invalid drawing data: " .. errorMessage)
            isValid, errorMessage = self.imageDataSchema:validate(drawingData.imageData)
            assert(isValid, "Invalid image data: " .. errorMessage)
        end
        return drawingData
    end)
    
    if success and result then
        debugPrint("Retrieved drawing for player %s, theme %s", player.Name, theme_uuid)
        
        return result, nil
    elseif success then
        -- No data found but operation succeeded
        debugPrint("No drawing found for player %s, theme %s", player.Name, theme_uuid)
        return nil, "No drawing found"
    else
        -- Operation failed
        warn("BackendService: Failed to retrieve drawing - " .. tostring(result))
        return nil, "DataStore error: " .. tostring(result)
    end
end

function PlayerBestDrawingsStore:savePlayerBestDrawing(player, theme_uuid, drawingData)
    assert(player, "Missing player parameter")
    assert(theme_uuid, "Missing theme parameter")
    assert(drawingData, "Missing drawingData parameter")
    
    -- Validate the drawing data against our schema
    local isValid, errorMessage = self.playerBestDrawingSchema:validate(drawingData)
    assert(isValid, "Invalid drawing data: " .. errorMessage)

    isValid, errorMessage = self.imageDataSchema:validate(drawingData.imageData)
    assert(isValid, "Invalid image data: " .. errorMessage)
    
    -- Create a unique key for this player and theme combination
    local key = self:generateDrawingKey(player.UserId, theme_uuid)
    
    -- Ensure playerId is included in the data
    drawingData.playerId = player.UserId
    
    -- Attempt to save the drawing data to the DataStore
    local success, result = pcall(function()
        -- Calculate data size
        local dataSize = #HttpService:JSONEncode(drawingData)
        debugPrint("Writing %d bytes to DataStore for key: %s", dataSize, key)
        
        -- Use the utility function with retry for DataStore operation
        local success, operationResult = DataStoreHelper:_performDataStoreOperationWithRetry(
            PlayerBestDrawingsDataStore, 
            "SetAsync", 
            key, 
            drawingData,
            true -- Enable retry
        )
        
        if not success then
            error("Failed to save data: " .. tostring(operationResult))
        end
        
        return true
    end)
    
    if success then
        debugPrint("Successfully saved drawing for player %s, theme %s with score %s", 
            player.Name, theme_uuid, tostring(drawingData.score))
            
        return true, nil
    else
        warn("BackendService: Failed to save drawing - " .. tostring(result))
        return false, "DataStore error: " .. tostring(result)
    end
end

return PlayerBestDrawingsStore
