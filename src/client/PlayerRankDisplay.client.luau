local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local GameConfig = require(ReplicatedStorage.Modules.GameData.GameConfig)
local RankConfig = require(ReplicatedStorage.Modules.GameData.RankConfig)

-- Get references to events
local Events = ReplicatedStorage:WaitForChild("Events")
local PlayerDataUpdatedEvent = Events:WaitForChild("PlayerDataUpdated")
local AllPlayersDataUpdatedEvent = Events:WaitForChild("AllPlayersDataUpdated")
local UIToggleStateChangedEvent = Events:WaitForChild("UIToggleStateChanged")

-- Constants for BillboardGui appearance
local BILLBOARD_SIZE = UDim2.new(4, 0, 1, 0)
local BILLBOARD_OFFSET = Vector3.new(0, 2, 0)
local NAME_TEXT_SIZE = UDim2.new(1, 0, 0.5, 0)
local RANK_TEXT_SIZE = UDim2.new(1, 0, 0.3, 0)

-- Pre-build a dictionary for quick color lookup by rank name
local RANK_COLORS = {}
for _, definition in ipairs(RankConfig.Definitions) do
    RANK_COLORS[definition.name] = definition.color
end

-- Store BillboardGuis for each player
local playerBillboards = {}

-- Track UI toggle state
local showUI = true

-- Function to update billboard visibility based on UI toggle state
local function updateBillboardVisibility()
    for _, billboardData in pairs(playerBillboards) do
        if billboardData.billboard then
            billboardData.billboard.Enabled = showUI
        end
    end
end

-- Function to create a BillboardGui for a player
local function createPlayerBillboard(player, character)
    -- Check if character exists
    if not character then 
        warn("Character not found for " .. player.Name)
        return 
    end
    
    -- Get the head to attach the BillboardGui to
    local head = character:WaitForChild("Head", GameConfig.HUMANOID_INIT_TIMEOUT)

    if not head then 
        warn("Head not found for " .. player.Name)
        return 
    end
    
    -- Create BillboardGui
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "PlayerRankDisplay"
    billboardGui.Size = BILLBOARD_SIZE
    billboardGui.StudsOffset = BILLBOARD_OFFSET
    billboardGui.Adornee = head
    billboardGui.AlwaysOnTop = true
    billboardGui.LightInfluence = 0
    billboardGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    billboardGui.Active = true
    
    -- Create container frame
    local frame = Instance.new("Frame")
    frame.Name = "Container"
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1
    frame.Parent = billboardGui
    
    -- Create player name label
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = NAME_TEXT_SIZE
    nameLabel.Position = UDim2.new(0, 0, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextStrokeTransparency = 0.5
    nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextScaled = true
    nameLabel.Text = player.Name
    nameLabel.Parent = frame
    
    -- Create rank label
    local rankLabel = Instance.new("TextLabel")
    rankLabel.Name = "RankLabel"
    rankLabel.Size = RANK_TEXT_SIZE
    rankLabel.Position = UDim2.new(0, 0, 0.5, 0)
    rankLabel.BackgroundTransparency = 1
    rankLabel.TextStrokeTransparency = 0.5
    rankLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    rankLabel.Font = Enum.Font.GothamBold
    rankLabel.TextScaled = true
    rankLabel.Text = ""
    rankLabel.Parent = frame
    
    -- Parent the BillboardGui to the character
    billboardGui.Parent = character
    
    -- Set initial visibility based on UI toggle state
    billboardGui.Enabled = showUI
    
    -- Store the BillboardGui
    playerBillboards[player.UserId] = {
        billboard = billboardGui,
        nameLabel = nameLabel,
        rankLabel = rankLabel,
    }
    
    return billboardGui
end

-- Function to update a player's BillboardGui with their rank and points
local function updatePlayerBillboard(player, playerData)
    if not player or not playerData then return end
    
    -- Get the player's points
    local points = playerData.TotalPoints
    if not points then return end
    
    -- Get the player's rank information
    local rankInfo = RankConfig.getRankForPoints(points)
    if not rankInfo then return end

    -- Get the BillboardGui for this player
    local billboardData = playerBillboards[player.UserId]
    if not billboardData then return end

    -- Update the rank label with points included
    billboardData.rankLabel.Text = string.format("%s (%s)", rankInfo.name, tostring(points))
    billboardData.rankLabel.TextColor3 = rankInfo.color or Color3.fromRGB(255, 255, 255)
end

-- Function to handle when a player's character is added
local function onCharacterAdded(player, character)
    -- Wait for the humanoid to exist to disable the default name tag
    local humanoid = character:WaitForChild("Humanoid", GameConfig.HUMANOID_INIT_TIMEOUT)
    if humanoid == nil then
        warn("Humanoid not found for " .. player.Name)
        return
    end

    if GameConfig.HIDE_DEFAULT_NAME then
        humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    end

    -- Create a new BillboardGui for the player
    local billboard = createPlayerBillboard(player, character)

    -- If this is the local player, request their data to update the billboard
    if player == LocalPlayer then
        -- The server should send player data when they join, but we can request it if needed
    end
end

-- Function to handle when a player's character is removed
local function onCharacterRemoved(player)
    -- Clean up the BillboardGui for this player
    local billboardData = playerBillboards[player.UserId]
    if billboardData and billboardData.billboard then
        billboardData.billboard:Destroy()
    end
    
    -- Remove the player from our tracking table
    playerBillboards[player.UserId] = nil
end

-- Function to handle when a player is added to the game
local function onPlayerAdded(player)
    -- Connect to the player's CharacterAdded event
    player.CharacterAdded:Connect(function(character)
        onCharacterAdded(player, character)
    end)
    
    -- Connect to the player's CharacterRemoving event
    player.CharacterRemoving:Connect(function()
        onCharacterRemoved(player)
    end)
    
    -- If the player already has a character, create a BillboardGui for them
    if player.Character then
        warn("Player character added : " .. player.Name)
        onCharacterAdded(player, player.Character)
    end
end

-- Function to handle when a player is removed from the game
local function onPlayerRemoving(player)
    onCharacterRemoved(player)
end

-- Function to handle when player data is updated (local player only)
local function onPlayerDataUpdated(playerData)
    if not playerData then return end
    
    -- Update the BillboardGui for the local player
    updatePlayerBillboard(LocalPlayer, playerData)
end

-- Function to handle when all players data is updated
local function onAllPlayersDataUpdated(allPlayerData)
    if not allPlayerData then return end
    
    -- Update billboards for all players
    for userId, playerData in pairs(allPlayerData) do
        local player = Players:GetPlayerByUserId(tonumber(userId))
        if player then
            updatePlayerBillboard(player, playerData)
        end
    end
end

-- Function to handle UI toggle state changes
local function onUIToggleStateChanged(newShowUI)
    showUI = newShowUI
    updateBillboardVisibility()
end

-- Connect to events
PlayerDataUpdatedEvent.OnClientEvent:Connect(onPlayerDataUpdated)
AllPlayersDataUpdatedEvent.OnClientEvent:Connect(onAllPlayersDataUpdated)
UIToggleStateChangedEvent.OnClientEvent:Connect(onUIToggleStateChanged)

-- Connect to the PlayerAdded and PlayerRemoving events
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Initialize existing players
for _, player in ipairs(Players:GetPlayers()) do
    warn("Creating billboard for Player : " .. player.Name)
    onPlayerAdded(player)
end

-- Cleanup function
local function cleanup()
    -- Disconnect events if needed
    -- Clean up BillboardGuis
    for _, billboardData in pairs(playerBillboards) do
        if billboardData.billboard then
            billboardData.billboard:Destroy()
        end
    end
    
    -- Clear the tracking table
    playerBillboards = {}
end

-- Return cleanup function
return cleanup
