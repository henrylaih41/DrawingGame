--!native
-- BackendService.luau
-- Module for communicating with the backend server

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CanvasDraw = require(ReplicatedStorage.Modules.Canvas.CanvasDraw)
local PromptService = require(ReplicatedStorage.Modules.Services.PromptService)
local SchemaValidator = require(ReplicatedStorage.Modules.Utils.SchemaValidator)
local BackendService = {}
local DEBUG_ENABLED = true
local DataStoreService = game:GetService("DataStoreService")

-- Create DataStores
local PlayerBestDrawingsStore = DataStoreService:GetDataStore("PlayerBestDrawings")
local PlayersDataStore = DataStoreService:GetDataStore("PlayersData")

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

-- Define schema for drawing data
local playerBestDrawingSchema = SchemaValidator.createSchema({
    imageData = { type = "table", required = true },
    score = { type = "number", required = true },
    timestamp = { type = "number", required = true },
    theme = { type = "string", required = true },
    playerId = { type = "number", required = true }
})

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
    coins = { type = "number", required = true }
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
function BackendService:getDrawingForTheme(player, theme)
    assert(player, "Missing player parameter")
    assert(theme, "Missing theme parameter")
    
    -- Create a unique key for this player and theme combination
    local key = generateDrawingKey(player.UserId, theme)
    
    -- Attempt to get the drawing data from the DataStore
    local success, result = pcall(function()
        local drawingData = PlayerBestDrawingsStore:GetAsync(key)
        
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
        debugPrint("Retrieved drawing for player %s, theme %s", player.Name, theme)
        
        return result, nil
    elseif success then
        -- No data found but operation succeeded
        debugPrint("No drawing found for player %s, theme %s", player.Name, theme)
        return nil, "No drawing found"
    else
        -- Operation failed
        warn("BackendService: Failed to retrieve drawing - " .. tostring(result))
        return nil, "DataStore error: " .. tostring(result)
    end
end

function BackendService:saveDrawingForTheme(player, theme, drawingData)
    assert(player, "Missing player parameter")
    assert(theme, "Missing theme parameter")
    assert(drawingData, "Missing drawingData parameter")
    
    -- Validate the drawing data against our schema
    local isValid, errorMessage = playerBestDrawingSchema:validate(drawingData)
    assert(isValid, "Invalid drawing data: " .. errorMessage)

    isValid, errorMessage = imageDataSchema:validate(drawingData.imageData)
    assert(isValid, "Invalid image data: " .. errorMessage)
    
    -- Create a unique key for this player and theme combination
    local key = generateDrawingKey(player.UserId, theme)
    
    -- Ensure playerId is included in the data
    drawingData.playerId = player.UserId
    
    -- Attempt to save the drawing data to the DataStore
    local success, result = pcall(function()
        -- Calculate data size
        local dataSize = #HttpService:JSONEncode(drawingData)
        debugPrint("Writing %d bytes to DataStore for key: %s", dataSize, key)
        PlayerBestDrawingsStore:SetAsync(key, drawingData)
        return true
    end)
    
    if success then
        debugPrint("Successfully saved drawing for player %s, theme %s with score %s", 
            player.Name, theme, tostring(drawingData.score))
            
        return true, nil
    else
        warn("BackendService: Failed to save drawing - " .. tostring(result))
        return false, "DataStore error: " .. tostring(result)
    end
end

-- Function to get a player's profile
function BackendService:getPlayer(player)
    assert(player, "Missing player parameter")
    
    local key = "Player_" .. player.UserId
    
    -- Attempt to get the player data from the DataStore
    local success, result = pcall(function()
        local playerData = PlayersDataStore:GetAsync(key)
        
        if playerData then
            -- Validate the data if it exists
            local isValid, errorMessage = playerDataSchema:validate(playerData)
            assert(isValid, "Invalid player data: " .. errorMessage)
        end
        
        return playerData
    end)
    
    if success and result then
        debugPrint("Retrieved player profile for %s", player.Name)
        return result, nil
    elseif success then
        -- No data found but operation succeeded, initialize player
        debugPrint("No player profile found for %s, creating new profile", player.Name)
        local newProfile = self:initializePlayerProfile(player)
        return newProfile, nil
    else
        -- Operation failed
        warn("BackendService: Failed to retrieve player profile - " .. tostring(result))
        return nil, "DataStore error: " .. tostring(result)
    end
end

-- Function to save a player's profile
function BackendService:setPlayer(player, playerData)
    assert(player, "Missing player parameter")
    assert(playerData, "Missing playerData parameter")
    
    -- Validate the player data against our schema
    local isValid, errorMessage = playerDataSchema:validate(playerData)
    assert(isValid, "Invalid player data: " .. errorMessage)
    
    local key = "Player_" .. player.UserId
    
    -- Attempt to save the player data to the DataStore
    local success, result = pcall(function()
        -- Calculate data size
        local dataSize = #HttpService:JSONEncode(playerData)
        debugPrint("Writing %d bytes to PlayersDataStore for key: %s", dataSize, key)
        PlayersDataStore:SetAsync(key, playerData)
        return true
    end)
    
    if success then
        debugPrint("Successfully saved player profile for %s", player.Name)
        return true, nil
    else
        warn("BackendService: Failed to save player profile - " .. tostring(result))
        return false, "DataStore error: " .. tostring(result)
    end
end

return BackendService 