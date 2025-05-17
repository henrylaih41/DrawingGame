--------------------------------------------------------------------
-- Top30WorkerClient.lua  •  Server-side only
-- Dependencies: HttpService.HttpEnabled = true (enable in Studio)
--------------------------------------------------------------------
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TopPlaysStore = require(ServerScriptService.modules.TopPlaysStore)

--------------------------------------------------------------------
-- CONFIG – edit to match your deployment
--------------------------------------------------------------------
local WORKER_BASE_URL = "http://localhost:3000"   -- trailing slash
local ENDPOINT = "/api/topPlays/"  -- Will append userId to this path
-- local WORKER_BASE_URL = "http://127.0.0.1:8787/"   -- trailing slash
local MAX_RETRIES     = 4          -- exponential back-off tries
local BASE_DELAY      = 2          -- seconds; grows per attempt

local topPlaysCache = {}

--------------------------------------------------------------------
-- INTERNAL UTILITY – robust RequestAsync with retries
--------------------------------------------------------------------
local function requestWithRetry(opts)
    for attempt = 1, MAX_RETRIES do
        local ok, resp = pcall(HttpService.RequestAsync, HttpService, opts)
        if ok and resp.Success then
            return resp                               -- ✅ success path
        end
        warn(("[Top30] HTTP %s failed (attempt %d/%d): %s")
             :format(opts.Method, attempt, MAX_RETRIES,
                     ok and resp.StatusCode or tostring(resp)))
        task.wait(BASE_DELAY ^ attempt)               -- simple back-off
    end
    warn("[Top30] All retries exhausted for "..opts.Url)
    return nil
end

--------------------------------------------------------------------
-- PUBLIC API
--------------------------------------------------------------------
local TopDrawingCacheService = {}

--- Fetches the cached top-30 record for a userId.
-- @param userId   number | string  Roblox userId
-- @return table                Lua table decoded from JSON
function TopDrawingCacheService.fetchFromExternalBackend(userId: string)
    local response = requestWithRetry({
        Url     = WORKER_BASE_URL .. ENDPOINT,
        Method  = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body    = HttpService:JSONEncode({ userId = userId }),
    })
    
    if not response then
        warn("[Top30] Failed to fetch top plays for user " .. userId)
        return nil
    end
    
    return HttpService:JSONDecode(response.Body)
end

function TopDrawingCacheService.fetchFromDatastore(userId: string)
    return TopPlaysStore:getTopPlays(userId)
end

--- Fetches the cached top-30 record for a userId.
-- @param userId   number | string  Roblox userId
-- @return table                Lua table decoded from JSON
function TopDrawingCacheService.fetch(userId)
    -- Check cache first
    if topPlaysCache[userId] then
        return topPlaysCache[userId]
    end

    -- Fetch from datastore
    local topPlays = TopDrawingCacheService.fetchFromDatastore(userId)

    if topPlays then
        topPlaysCache[userId] = topPlays
    end 

    return topPlays
end

function TopDrawingCacheService.purgeCache(userId: string)
    topPlaysCache[userId] = nil
end

return TopDrawingCacheService