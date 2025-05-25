-- CanvasManager.lua
-- Handles canvas state management operations

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = ReplicatedStorage:WaitForChild("Events")

local ServerStates = require(script.Parent.ServerStates)

local CanvasManager = {}

-- Resets a canvas to its default state and makes it available for registration
function CanvasManager.resetCanvas(canvas)
    if canvas == nil then
        warn("Canvas is nil in resetCanvas")
        return
    end

    print("Resetting canvas")
    -- Unregister the canvas.
    ServerStates.CanvasState[canvas].registered = false
    ServerStates.CanvasState[canvas].ownerPlayer = nil
    ServerStates.CanvasState[canvas].ownedCanvasIndex = nil
    ServerStates.CanvasState[canvas].drawing = nil
    
    -- Re-enable the register prompt.
    local registerPrompt = canvas:FindFirstChild("CanvasFrame"):FindFirstChild("RegisterCanvasPrompt")
    if registerPrompt then
        registerPrompt.Enabled = true
    end
    
    -- Clear canvas display for all clients
    Events.DrawToCanvas:FireAllClients(nil, 
        {themeName = nil, canvas = canvas, playerId = nil, drawingId = nil})
end

return CanvasManager 