-- UIToggleService.client.luau
-- A client-side service to manage UI toggle state across different client scripts

local UIToggleService = {}

-- Create a BindableEvent for local client-side communication
local UIToggleStateChanged = Instance.new("BindableEvent")

-- Default UI state is visible
local showUI = true

-- Function to toggle UI visibility
function UIToggleService:ToggleUI(newState)
    if newState ~= nil then
        showUI = newState
    else
        showUI = not showUI
    end
    
    -- Fire the event to notify all listeners
    UIToggleStateChanged:Fire(showUI)
    
    return showUI
end

-- Function to get current UI state
function UIToggleService:GetUIState()
    return showUI
end

-- Function to connect a callback to the UI toggle event
function UIToggleService:OnUIToggleStateChanged(callback)
    return UIToggleStateChanged.Event:Connect(callback)
end

return UIToggleService
