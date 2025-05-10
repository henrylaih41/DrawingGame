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
local WORKER_BASE_URL = "https://top-drawing-kv-store.henrylaih41.workers.dev"   -- trailing slash
-- local WORKER_BASE_URL = "http://127.0.0.1:8787/"   -- trailing slash
local ADMIN_KEY       = "EPvY7rNWR13ONIvxtzof4" -- keep server-side only!
local MAX_RETRIES     = 4          -- exponential back-off tries
local BASE_DELAY      = 2          -- seconds; grows per attempt

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
function TopDrawingCacheService.fetch(userId)
    local result, _ = TopPlaysStore:getTopPlays(userId)
    return result
    -- Getting 520 error from the worker. Let's fallback to datastore for now.
    -- local response = requestWithRetry({
    --     Url     = WORKER_BASE_URL .. tostring(userId),
    --     Method  = "GET",
    --     Headers = { ["Content-Type"] = "application/json" },
    -- })
    -- return HttpService:JSONDecode(response.Body)
end

--- Purges the userId’s cache entry after they set a new score.
-- Only call this from server code that knows ADMIN_KEY.
-- @return boolean   true if Worker responded 200
function TopDrawingCacheService.purge(userId)
    local resp = requestWithRetry({
        Url     = WORKER_BASE_URL .. tostring(userId),
        Method  = "DELETE",                   -- matches Worker snippet
        Headers = { ["X-Admin-Key"] = ADMIN_KEY },
        Timeout = 10,
    })
    return resp.StatusCode == 200
end

return TopDrawingCacheService