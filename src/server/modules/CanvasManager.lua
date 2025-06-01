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

    local player = ServerStates.CanvasState[canvas].ownerPlayer

    -- When we reset the canvas, the player may not be in the server.
    -- Or, the owner is actually the server, which the value is nil.
    if player then
        -- If the player is in the server, remove the canvas from the player's ownedCanvas.
        local ownedCanvasList = ServerStates.PlayerState[player].ownedCanvas
        for i, ownedCanvas in ipairs(ownedCanvasList) do
        if ownedCanvas == canvas then
            table.remove(ownedCanvasList, i)
                break
            end
        end
        -- Notify the client that the canvas has been unregistered.
        Events.UnregisterCanvas:FireClient(player, canvas)
    end
        
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