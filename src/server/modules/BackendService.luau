--!native
-- BackendService.luau
-- Module for communicating with the backend server

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CanvasDraw = require(ReplicatedStorage.Modules.Canvas.CanvasDraw)
local PromptService = require(ReplicatedStorage.Modules.Services.PromptService)
local SchemaValidator = require(ServerScriptService.modules.SchemaValidator)
local BackendService = {}
local DEBUG_ENABLED = true

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

return BackendService 