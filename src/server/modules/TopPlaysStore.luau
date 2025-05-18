local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Modules.GameData.GameConfig)
local DataStoreHelper = require(ServerScriptService.modules.DataStoreHelper)
local PlayerBestDrawingsStore = require(ServerScriptService.modules.PlayerBestDrawingsStore)
local TopPlaysDataStore = DataStoreService:GetDataStore("TopPlays")
local DEBUG_ENABLED = true

-- Debug print function that only outputs when debugging is enabled
local function debugPrint(message, ...)
    if DEBUG_ENABLED then
        print(string.format(message, ...))
    end
end

local TopPlaysStore = {}

-- Define schema for best drawings
local playerBestDrawingSchema = PlayerBestDrawingsStore.playerBestDrawingSchema

-- Top Plays Management
function TopPlaysStore:checkIfNewBestDrawingChangesTopPlays(originTopPlaysWithoutImageData, newTopPlay)
    assert(originTopPlaysWithoutImageData, "Missing originTopPlays parameter")
    assert(newTopPlay, "Missing newTopPlay parameter")

    -- Validate the new top play against schema
    local valid, errors = playerBestDrawingSchema:validate(newTopPlay)
    if not valid then
        warn("TopPlaysStore: Invalid top play data: " .. HttpService:JSONEncode(errors))
        return false, nil
    end
    
    -- Check if the new play should be added to top plays
    local shouldAdd = false
    local replaceThemeUuid = nil
    
    -- Check if this theme already exists in the top plays
    local existingPlayIndex = nil
    local lowestPointsIndex = nil
    local lowestPoints = nil
    
    -- Find existing play with same theme and track lowest points
    for i, play in ipairs(originTopPlaysWithoutImageData) do
        -- Track the play with lowest points
        if lowestPoints == nil or play.points < lowestPoints then
            lowestPoints = play.points
            lowestPointsIndex = i
        end
        
        -- Check if this theme already exists
        if play.theme_uuid == newTopPlay.theme_uuid then
            existingPlayIndex = i
        end
    end
    
    -- CASE 1: Theme exists in top plays
    if existingPlayIndex then
        -- Only replace if new score is higher
        if newTopPlay.points > originTopPlaysWithoutImageData[existingPlayIndex].points then
            shouldAdd = true
            replaceThemeUuid = newTopPlay.theme_uuid
        end
        -- Otherwise do nothing (keep existing score)
    
    -- CASE 2: Theme doesn't exist in top plays
    else
        -- If under limit, we can just append
        if #originTopPlaysWithoutImageData < GameConfig.GALLERY_SLOTS then
            shouldAdd = true
        -- If at limit, replace lowest score if new score is higher
        elseif newTopPlay.points > lowestPoints then
            shouldAdd = true
            replaceThemeUuid = originTopPlaysWithoutImageData[lowestPointsIndex].theme_uuid
        end
    end
    
    return shouldAdd, replaceThemeUuid
end

function TopPlaysStore:saveTopPlays(userId, topPlays)
    assert(userId, "Missing userId parameter")
    assert(topPlays, "Missing topPlays parameter")

    for _, topPlay in ipairs(topPlays) do
        -- Validate the schema
        local valid, errors = playerBestDrawingSchema:validate(topPlay)
        if not valid then
            warn(errors)
            return false, "Invalid top play data"
        end
    end

    local success, error = DataStoreHelper:_performDataStoreOperationWithRetry(
        TopPlaysDataStore,
        "SetAsync",
        "Player_" .. userId, 
        topPlays,
        true)

    if not success then
        warn("TopPlaysStore: Failed to save top plays for player " .. userId .. ": " .. tostring(error))
        return false, "Failed to save top plays: " .. tostring(error)
    end

    return true, nil
end

function TopPlaysStore:getTopPlays(userId: string)
    if not userId then
        warn("TopPlaysStore: Missing userId parameter")
        return nil, "Missing userId parameter"
    end
    
    -- Try to get top plays data from DataStore with retry logic
    local success, result = DataStoreHelper:_performDataStoreOperationWithRetry(
        TopPlaysDataStore,
        "GetAsync",
        "Player_" .. userId 
    )
    
    if success and result then
        -- Validate the schema
        for _, topPlay in ipairs(result) do

            -- Generate a UUID if it doesn't exist
            if topPlay.uuid == nil then
                warn("[Self Healing] Generating UUID for top play")
                topPlay.uuid = HttpService:GenerateGUID(false)
                -- Save the top play data
                self:saveTopPlays(userId, result)
            end
            local valid, errors = playerBestDrawingSchema:validate(topPlay)
            if not valid then
                warn(errors)
            end
        end
        
        -- Sort plays by points in descending order
        table.sort(result, function(a, b)
            return a.points > b.points
        end)
        
        return result, nil
    elseif success then
        -- No data found but operation succeeded, return empty table
        debugPrint("No top plays found for player %s", userId)
        return {}, nil
    else
        -- Operation failed
        warn("TopPlaysStore: Failed to retrieve top plays - " .. tostring(result))
        warn(tostring(result))
        return nil, "DataStore error: " .. tostring(result)
    end
end

return TopPlaysStore
