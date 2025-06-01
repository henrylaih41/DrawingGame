-- CanvasTTLManager.lua
-- Manages the TTL (Time To Live) for canvas drawings

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerConfig = require(ServerScriptService.modules.ServerConfig)
local ServerStates = require(ServerScriptService.modules.ServerStates)
local Events = ReplicatedStorage:WaitForChild("Events")

local CanvasTTLManager = {}

-- Store expiration times for each canvas
local canvasExpirationTimes = {} -- [canvas] = expirationTime

-- Store cleanup callback
local cleanupCallback = nil

-- Store if the cleanup loop is running
local cleanupLoopRunning = false

-- Get current server time in seconds
local function getCurrentTime()
    return os.time()
end

function CanvasTTLManager.setCanvasExpirationTime(canvas, expirationTime)
    canvasExpirationTimes[canvas] = expirationTime
    Events.CanvasTTLUpdated:FireAllClients(canvas, expirationTime)
end

-- Set the initial TTL for a canvas
function CanvasTTLManager.setCanvasTTL(canvas, minutes)
    if not canvas then
        warn("CanvasTTLManager.setCanvasTTL: canvas is nil")
        return
    end
    
    local expirationTime = getCurrentTime() + (minutes * 60)
    CanvasTTLManager.setCanvasExpirationTime(canvas, expirationTime)
    
    print(string.format("Canvas TTL set to expire in %d minutes (at %d)", minutes, expirationTime))
end

-- Extend the TTL for a canvas
function CanvasTTLManager.extendCanvasTTL(canvas, additionalMinutes)
    if not canvas then
        warn("CanvasTTLManager.extendCanvasTTL: canvas is nil")
        return
    end
    
    local currentExpiration = canvasExpirationTimes[canvas]
    if not currentExpiration then
        warn("CanvasTTLManager.extendCanvasTTL: No TTL set for canvas")
        return
    end
    
    -- Calculate new expiration time
    local newExpiration = currentExpiration + (additionalMinutes * 60)
    
    -- Cap at maximum TTL
    local maxExpiration = getCurrentTime() + (ServerConfig.CANVAS_TTL.MAXIMUM_TTL_MINUTES * 60)
    if newExpiration > maxExpiration then
        newExpiration = maxExpiration
    end
    
    CanvasTTLManager.setCanvasExpirationTime(canvas, newExpiration)
    print(string.format("Canvas TTL extended by %d minutes (new expiration: %d)", additionalMinutes, newExpiration))
end

-- Reduce the TTL for a canvas
function CanvasTTLManager.reduceCanvasTTL(canvas, reductionMinutes)
    if not canvas then
        warn("CanvasTTLManager.reduceCanvasTTL: canvas is nil")
        return
    end
    
    local currentExpiration = canvasExpirationTimes[canvas]
    if not currentExpiration then
        warn("CanvasTTLManager.reduceCanvasTTL: No TTL set for canvas")
        return
    end
    
    -- Calculate new expiration time
    local newExpiration = currentExpiration - (reductionMinutes * 60)
    
    -- Ensure minimum TTL
    local minExpiration = getCurrentTime() + (ServerConfig.CANVAS_TTL.MINIMUM_TTL_MINUTES * 60)
    if newExpiration < minExpiration then
        newExpiration = minExpiration
    end
    
    CanvasTTLManager.setCanvasExpirationTime(canvas, newExpiration)
    print(string.format("Canvas TTL reduced by %d minutes (new expiration: %d)", reductionMinutes, newExpiration))
end

-- Clear the TTL for a canvas
function CanvasTTLManager.clearCanvasTTL(canvas)
    if canvas then
        CanvasTTLManager.setCanvasExpirationTime(canvas, nil)
    end
end

-- Check if a canvas has expired
function CanvasTTLManager.isCanvasExpired(canvas)
    local expirationTime = canvasExpirationTimes[canvas]
    if not expirationTime then
        return false
    end
    
    return getCurrentTime() >= expirationTime
end

-- Cleanup expired canvases
local function cleanupExpiredCanvases()
    local currentTime = getCurrentTime()
    local expiredCanvases = {}
    
    -- Find all expired canvases
    for canvas, expirationTime in pairs(canvasExpirationTimes) do
        if currentTime >= expirationTime then
            table.insert(expiredCanvases, canvas)
        end
    end
    
    -- Reset expired canvases
    for _, canvas in ipairs(expiredCanvases) do
        print(string.format("Canvas TTL expired, resetting canvas"))
        
        -- Clear the TTL entry
        CanvasTTLManager.setCanvasExpirationTime(canvas, nil)
    end
    
    if #expiredCanvases > 0 then
        print(string.format("Cleaned up %d expired canvases", #expiredCanvases))
    end
    
    return expiredCanvases
end

-- Set the cleanup callback function
function CanvasTTLManager.setCleanupCallback(callback)
    cleanupCallback = callback
end

-- Start the cleanup loop
function CanvasTTLManager.startCleanupLoop()
    if cleanupLoopRunning then
        return
    end
    
    cleanupLoopRunning = true
    
    task.spawn(function()
        while cleanupLoopRunning do
            local expiredCanvases = cleanupExpiredCanvases()
            
            -- Call the cleanup callback for each expired canvas
            if cleanupCallback and #expiredCanvases > 0 then
                for _, canvas in ipairs(expiredCanvases) do
                    cleanupCallback(canvas)
                end
            end
            
            task.wait(ServerConfig.CANVAS_TTL.CLEANUP_INTERVAL_SECONDS)
        end
    end)
    
    print("Canvas TTL cleanup loop started")
end

-- Stop the cleanup loop
function CanvasTTLManager.stopCleanupLoop()
    cleanupLoopRunning = false
    print("Canvas TTL cleanup loop stopped")
end

-- Get remaining TTL for a canvas in minutes
function CanvasTTLManager.getRemainingTTL(canvas)
    local expirationTime = canvasExpirationTimes[canvas]
    if not expirationTime then
        return nil
    end
    
    local remainingSeconds = expirationTime - getCurrentTime()
    if remainingSeconds <= 0 then
        return 0
    end
    
    return math.ceil(remainingSeconds / 60)
end

-- Debug function to get all canvas TTL info
function CanvasTTLManager.debugGetAllTTLs()
    local ttlInfo = {}
    for canvas, expirationTime in pairs(canvasExpirationTimes) do
        local remainingMinutes = CanvasTTLManager.getRemainingTTL(canvas)
        if remainingMinutes then
            table.insert(ttlInfo, {
                canvas = canvas,
                remainingMinutes = remainingMinutes,
                expirationTime = expirationTime
            })
        end
    end
    return ttlInfo
end

function CanvasTTLManager.getCanvasExpirationTime(canvas)
    return canvasExpirationTimes[canvas]
end

return CanvasTTLManager 