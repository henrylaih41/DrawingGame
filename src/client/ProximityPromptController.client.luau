local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = ReplicatedStorage:WaitForChild("Events")
local PPS = game:GetService("ProximityPromptService")
local LocalPlayer = game:GetService("Players").LocalPlayer
local ClientState = require(LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("ClientState"))
local GameConstants = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameData"):WaitForChild("GameConstants"))

local PromptUtils = require(ReplicatedStorage.Modules.Utils.PromptUtils)

Events.RegisterCanvas.OnClientEvent:Connect(function(canvas)
    local frame = canvas:FindFirstChild("CanvasFrame")

    if not frame then 
        warn("CanvasFrame not found for canvas")
        return 
    end

    if frame:FindFirstChild("DrawPrompt") then return end

    local drawPrompt = PromptUtils.createPrompt("DrawPrompt", "Draw", "Canvas", 0.5, 8, Enum.KeyCode.E)
    drawPrompt.Parent = canvas:FindFirstChild("CanvasFrame")
    local unregisterPrompt = PromptUtils.createPrompt("UnregisterCanvasPrompt", "Unclaim", "Canvas", 0.5, 8, Enum.KeyCode.U)
    unregisterPrompt.UIOffset = Vector2.new(0, 80)
    unregisterPrompt.Parent = canvas:FindFirstChild("CanvasFrame")
end)

Events.UnregisterCanvas.OnClientEvent:Connect(function(canvas)
    print("UnregisterCanvas")
    -- Now we are unregistered from this canvas. We need to destroy the client-side prompts.
    local frame = canvas:FindFirstChild("CanvasFrame")
    if not frame then return end

    for _, name in ipairs({"DrawPrompt", "UnregisterCanvasPrompt"}) do
        local p = frame:FindFirstChild(name)
        if p then p:Destroy() end
    end
end)

-- We need to handle client-side only prompts.
PPS.PromptTriggered:Connect(function(prompt, player)
    -- If the player is drawing, we don't want to retrigger the client-side prompt.
    if ClientState.PlayerState ~= GameConstants.PlayerStateEnum.IDLE then
        return
    end

    if prompt.Name == "DrawPrompt" then
        local canvas = prompt.Parent.Parent
        Events.ClientStateChange:FireServer(GameConstants.PlayerStateEnum.THEME_LIST, {canvas = canvas})
    elseif prompt.Name == "UnregisterCanvasPrompt" then
        local canvas = prompt.Parent.Parent
        Events.UnregisterCanvas:FireServer(canvas)
    end
end)
