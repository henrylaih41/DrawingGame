--!native
-- BackendService.luau
-- Module for communicating with the backend server

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CanvasDraw = require(ReplicatedStorage.Modules.Canvas.CanvasDraw)
local PromptService = require(ReplicatedStorage.Modules.Services.PromptService)
local SchemaValidator = require(ReplicatedStorage.Modules.Utils.SchemaValidator)
local GameConfig = require(ReplicatedStorage.Modules.GameData.GameConfig)
local BackendService = {}
local DEBUG_ENABLED = true
local DataStoreService = game:GetService("DataStoreService")

-- Create DataStores
local PlayerBestDrawingsStore = DataStoreService:GetDataStore("PlayerBestDrawings")
local PlayersDataStore = DataStoreService:GetDataStore("Players")
local ThemesDataStore = DataStoreService:GetDataStore("Themes")
local ThemePagesDataStore = DataStoreService:GetDataStore("ThemePages")
local TopPlaysDataStore = DataStoreService:GetDataStore("TopPlays")

local TOP_PLAYS_LIMIT = 10

local function generateDrawingKey(playerId, theme_uuid)
    return string.format("%d_%s", playerId, theme_uuid)
end

-- Debug print function that only outputs when debugging is enabled
local function debugPrint(message, ...)
    if DEBUG_ENABLED then
        print(string.format(message, ...))
    end
end

-- Configuration
BackendService.BaseUrl = "https://drawing-backend.vercel.app"
-- BackendService.BaseUrl = "http://localhost:3000"
BackendService.Endpoints = {
    OPENAI = "/api/openai"
}

-- Default options for requests
BackendService.DefaultOptions = {
    Timeout = 30, -- 30 seconds timeout
    RetryCount = 2,
    Headers = {
        ["Content-Type"] = "application/json"
    }
}

-- Define schema for image data
local imageDataSchema = SchemaValidator.createSchema({
    ImageBuffer = { type = "string", required = true },
    Width = { type = "number", required = true },
    Height = { type = "number", required = true }
})

-- Define schema for player data
local playerDataSchema = SchemaValidator.createSchema({
    Name = { type = "string", required = true },
    TotalPlayCount = { type = "number", required = true },
    TotalPoints = { type = "number", required = true },
    Energy = { type = "number", required = true },
    coins = { type = "number", required = true },
    topPlaysWithoutImage = { type = "table", required = false}
})

-- Define schema for best drawings
local playerBestDrawingSchema = SchemaValidator.createSchema({
    imageData = { type = "table", required = true },
    score = { type = "number", required = true },
    points = { type = "number", required = true }, -- Added points field
    timestamp = { type = "number", required = true },
    theme = { type = "string", required = true },
    theme_uuid = { type = "string", required = true }, -- Added theme_uuid field
    playerId = { type = "number", required = true }
})

-- Define schema for theme data
local themeSchema = SchemaValidator.createSchema({
    Name = { type = "string", required = true },
    Description = { type = "string", required = true },
    GradingPrompt = { type = "string", required = true },
    Difficulty = { type = "number", required = true },
    TotalPlayCount = { type = "number", required = true },
    Duration = { type = "number", required = true },
    CreatedBy = { type = "string", required = true },
    CreatedAt = { type = "string", required = true },
    uuid = { type = "string", required = true },
    pageID = { type = "string", required = true }
})

-- Define schema for theme page
local themePageSchema = SchemaValidator.createSchema({
    themes = { type = "table", required = true }
})

-- Function to send a request to the OpenAI endpoint
function BackendService:SendOpenAIRequest(compressedImageData, prompt, theme, playerId)
    assert(compressedImageData, "Missing compressedImageData parameter")
    assert(prompt, "Missing prompt parameter")
    assert(theme, "Missing theme parameter")
    assert(playerId, "Missing playerId parameter")

    -- Schema for the image data understood by the server API.
    local imageDataForServer = {
        Pixels = compressedImageData.ImageBuffer,
        Width = compressedImageData.Width,
        Height = compressedImageData.Height
    }

    
    local requestBody = {
        image = imageDataForServer,
        prompt = prompt,
        metadata = {
            playerId = playerId,
            theme = theme  -- Move theme into metadata
        }
    }
    
    return self:Post(self.Endpoints.OPENAI, requestBody)
end

-- Base function to send a POST request to any endpoint
function BackendService:Post(endpoint, data, options)
    assert(endpoint, "Missing endpoint parameter")
    assert(data, "Missing data parameter")
    
    options = options or {}
    
    -- Merge default options with provided options
    for key, value in pairs(self.DefaultOptions) do
        if options[key] == nil then
            options[key] = value
        end
    end
    
    -- Convert data to JSON
    local jsonData = HttpService:JSONEncode(data)
    
    -- Build the full URL
    local url = self.BaseUrl .. endpoint
    
    -- Make the request
    local success, response = pcall(function()
        return HttpService:RequestAsync({
            Url = url,
            Method = "POST",
            Headers = options.Headers,
            Body = jsonData
        })
    end)
    
    if not success then
        warn("BackendService: HTTP request failed - " .. tostring(response))
        return nil, "Request failed: " .. tostring(response)
    end
    
    -- Check if the request was successful (status code 200-299)
    if response.Success then
        -- Try to parse the response body as JSON
        local responseData = nil
        local parseSuccess, parseError = pcall(function()
            responseData = HttpService:JSONDecode(response.Body)
        end)
        
        if parseSuccess then
            return responseData, nil
        else
            warn("BackendService: Failed to parse response body as JSON: " .. parseError)
            return nil, "Failed to parse response body as JSON"
        end
    else
        warn("BackendService: HTTP request failed with status " .. response.StatusCode)
        return nil, "Request failed with status " .. response.StatusCode .. ": " .. response.Body
    end
end

local function printDataStoreQuota(operationName)
    assert(operationName, "Missing operationName parameter")

    local quotaName = nil
    if operationName == "SetAsync" then
        quotaName = "SetIncrementAsync"
    else
        quotaName = operationName
    end

    -- Find the matching enum value
    local targetRequestType = nil
    for _, reqType in ipairs(Enum.DataStoreRequestType:GetEnumItems()) do
        if reqType.Name == quotaName then
            targetRequestType = reqType
            break
        end
    end
    
    if not targetRequestType then
        warn("Invalid DataStoreRequestType name: " .. quotaName)
        return
    end
    
    -- Get and print the quota for just this request type
    local remaining = DataStoreService:GetRequestBudgetForRequestType(targetRequestType)
    print("─ DataStore request budget for " .. quotaName .. " ─")
    print(string.format("  %-22s : %.0f requests left", quotaName, remaining))
    print("───────────────────────────────────────────────")
end

local function printAllDataStoreQuota()
    print("─ Current DataStore request budget (remaining this minute) ─")
    for _, reqType in ipairs(Enum.DataStoreRequestType:GetEnumItems()) do
        local remaining = DataStoreService:GetRequestBudgetForRequestType(reqType)
        -- remaining is a floating-point number that refills continuously
        print(string.format("  %-22s : %.0f requests left", reqType.Name, remaining))
    end
    print("────────────────────────────────────────────────────────────")
end

-- Player Data Management Functions
function BackendService:getPlayer(player)
    assert(player, "Missing player parameter")
    local playerId = player.UserId
    
    local success, result = self:_performDataStoreOperationWithRetry(
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

function BackendService:savePlayer(player, playerData)
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
    local success, error = self:_performDataStoreOperationWithRetry(
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

-- Theme Management Functions
function BackendService:getTheme(themeUuid)

end

-- Function to get themes from a specific page
function BackendService:getThemePage(pageId)

end

-- Best Drawings Management
function BackendService:saveBestDrawing(playerId, themeUuid, drawingData)

end

function BackendService:getBestDrawing(playerId, themeUuid)

end

-- Top Plays Management
function BackendService:checkIfNewBestDrawingChangesTopPlays(originTopPlaysWithoutImageData, newTopPlay)
    assert(originTopPlaysWithoutImageData, "Missing originTopPlays parameter")
    assert(newTopPlay, "Missing newTopPlay parameter")

    -- Validate the new top play against schema
    local valid, errors = playerBestDrawingSchema:validate(newTopPlay)
    if not valid then
        warn("BackendService: Invalid top play data: " .. HttpService:JSONEncode(errors))
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
        if #originTopPlaysWithoutImageData < GameConfig.TOP_PLAYS_LIMIT then
            shouldAdd = true
        -- If at limit, replace lowest score if new score is higher
        elseif newTopPlay.points > lowestPoints then
            shouldAdd = true
            replaceThemeUuid = originTopPlaysWithoutImageData[lowestPointsIndex].theme_uuid
        end
    end
    
    return shouldAdd, replaceThemeUuid
end

function BackendService:saveTopPlays(player, topPlays)
    local playerId = player.UserId
    assert(player, "Missing player parameter")
    assert(topPlays, "Missing topPlays parameter")

    for _, topPlay in ipairs(topPlays) do
        -- Validate the schema
        local valid, errors = playerBestDrawingSchema:validate(topPlay)
        if not valid then
            warn(errors)
            return false, "Invalid top play data"
        end
    end

    -- Log the topPlays bytes
    local dataSize = #HttpService:JSONEncode(topPlays)
    warn("Writing %d bytes to TopPlays for key: %s", dataSize, "Player_" .. playerId)

    local success, error = self:_performDataStoreOperationWithRetry(
        TopPlaysDataStore,
        "SetAsync",
        "Player_" .. playerId, 
        topPlays,
        true)

    if not success then
        warn("BackendService: Failed to save top plays for player " .. playerId .. ": " .. tostring(error))
        return false, "Failed to save top plays: " .. tostring(error)
    end

    return true, nil
end

function BackendService:getTopPlays(player)
    assert(player, "Missing player parameter")
    local playerId = player.UserId
    
    -- Try to get top plays data from DataStore with retry logic
    local success, result = self:_performDataStoreOperationWithRetry(
        TopPlaysDataStore,
        "GetAsync",
        "Player_" .. playerId
    )
    
    if success and result then
        -- Validate the schema
        for _, topPlay in ipairs(result) do
            local valid, errors = playerBestDrawingSchema:validate(topPlay)
            if not valid then
                warn(errors)
                return nil, "Invalid top play data"
            end
        end
        
        -- Sort plays by points in descending order
        table.sort(result, function(a, b)
            return a.points > b.points
        end)
        
        return result, nil
    elseif success then
        -- No data found but operation succeeded, return empty table
        debugPrint("No top plays found for player %s", playerId)
        return {}, nil
    else
        -- Operation failed
        warn("BackendService: Failed to retrieve top plays - " .. tostring(result))
        return nil, "DataStore error: " .. tostring(result)
    end
end

-- Utility function to convert an image to base64
-- Note: This requires the image to be in a format Roblox can read
function BackendService:ImageToBase64(image)
    assert(typeof(image) == "Instance" and image:IsA("ContentProvider"), 
        "Image must be a valid Roblox content instance")
    
    -- This is a placeholder - actual implementation would depend on
    -- how you're handling images in your game
    error("Image to base64 conversion must be implemented based on your specific needs")
    
    -- If you're using HTTP requests to fetch images that you then want to send to your backend,
    -- you might just want to pass the base64 data through rather than converting it again
end

-- TODO: Allow players to choose different prompts other than the BASIC_PROMPT.
--       Some ideas include the SPONG BOB PROMPT, PIXAR PROMPT, etc.
function BackendService:submitDrawingToBackendForGrading(player, imageData, theme)
    -- Assert that we have valid image data before proceeding
    if not imageData then
        warn("submitDrawingToBackendForGrading called with nil imageData for player: " .. player.Name)
        return nil, "Missing imageData"
    end

    -- Compress the image data using CanvasDraw utility
    local compressedImageData = CanvasDraw.CompressImageDataCustom(imageData)

    -- Assert that we have the compressed image data before proceeding
    if not compressedImageData then
        warn("submitDrawingToBackendForGrading failed to compress image data for player: " .. player.Name)
        return nil, "Failed to compress image data"
    end

    -- Get the prompt from the PromptService
    local prompt = PromptService:getPrompt("BASIC_PROMPT", theme)
    if not prompt then
        warn("submitDrawingToBackendForGrading failed to get prompt for player: " .. player.Name .. " with theme: " .. tostring(theme))
        return nil, "Failed to get prompt"
    end

    local responseData, error =
        BackendService:SendOpenAIRequest(compressedImageData, prompt, theme, player.UserId)

    if not responseData then
        warn("submitDrawingToBackendForGrading failed to get response data for player: " .. player.Name)
        return nil, "Failed to get response data"
    else
        debugPrint("submitDrawingToBackendForGrading received response data for player: " .. player.Name)
        print(responseData)
    end

    return responseData, error, compressedImageData
end

-- Function to get a player's drawing for a specific theme
function BackendService:getPlayerBestDrawing(player, theme_uuid)
    assert(player, "Missing player parameter")
    assert(theme_uuid, "Missing theme parameter")
    
    -- Create a unique key for this player and theme combination
    local key = generateDrawingKey(player.UserId, theme_uuid)
    
    -- Attempt to get the drawing data from the DataStore
    local success, result = pcall(function()
        -- Use the utility function with retry for DataStore operation
        local success, drawingData = self:_performDataStoreOperationWithRetry(
            PlayerBestDrawingsStore, 
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
            local isValid, errorMessage = playerBestDrawingSchema:validate(drawingData)
            assert(isValid, "Invalid drawing data: " .. errorMessage)
            isValid, errorMessage = imageDataSchema:validate(drawingData.imageData)
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

function BackendService:savePlayerBestDrawing(player, theme_uuid, drawingData)
    assert(player, "Missing player parameter")
    assert(theme_uuid, "Missing theme parameter")
    assert(drawingData, "Missing drawingData parameter")
    
    -- Validate the drawing data against our schema
    local isValid, errorMessage = playerBestDrawingSchema:validate(drawingData)
    assert(isValid, "Invalid drawing data: " .. errorMessage)

    isValid, errorMessage = imageDataSchema:validate(drawingData.imageData)
    assert(isValid, "Invalid image data: " .. errorMessage)
    
    -- Create a unique key for this player and theme combination
    local key = generateDrawingKey(player.UserId, theme_uuid)
    
    -- Ensure playerId is included in the data
    drawingData.playerId = player.UserId
    
    -- Attempt to save the drawing data to the DataStore
    local success, result = pcall(function()
        -- Calculate data size
        local dataSize = #HttpService:JSONEncode(drawingData)
        debugPrint("Writing %d bytes to DataStore for key: %s", dataSize, key)
        
        -- Use the utility function with retry for DataStore operation
        local success, operationResult = self:_performDataStoreOperationWithRetry(
            PlayerBestDrawingsStore, 
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

-- Private utility function for handling DataStore operations with retry logic
function BackendService:_performDataStoreOperationWithRetry(dataStore, operation, key, value, retry)
    local retry = retry or true
    local MAX_RETRIES = 5
    local success, result
    for attempt = 1, MAX_RETRIES do
        printDataStoreQuota(operation)
        success, result = pcall(function()
            if operation == "GetAsync" then
                return dataStore:GetAsync(key)
            elseif operation == "SetAsync" then
                dataStore:SetAsync(key, value)
                return true
            else
                error("Unsupported operation: " .. operation)
            end
        end)
        
        if success or not retry then
            break
        else 
            warn(result)
            -- Exponential backoff
            task.wait(1 * 2 ^ (attempt - 1))
        end
    end
    
    return success, result
end

return BackendService 