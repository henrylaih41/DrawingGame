local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Get references to events
local Events = ReplicatedStorage:WaitForChild("Events")
local PlayerDataUpdatedEvent = Events:WaitForChild("PlayerDataUpdated")

-- Constants for BillboardGui appearance
local BILLBOARD_SIZE = UDim2.new(4, 0, 1, 0)
local BILLBOARD_OFFSET = Vector3.new(0, 2, 0)
local NAME_TEXT_SIZE = UDim2.new(1, 0, 0.5, 0)
local RANK_TEXT_SIZE = UDim2.new(1, 0, 0.3, 0)

-- Rank colors based on tier
local RANK_COLORS = {
    ["Beginner"] = Color3.fromRGB(200, 200, 200),         -- Plain paper badge
    ["Rookie Artist"] = Color3.fromRGB(150, 150, 150),    -- Pencil-grey badge
    ["Sketch Star"] = Color3.fromRGB(135, 206, 235),      -- Pastel-blue badge
    ["Art Adept"] = Color3.fromRGB(75, 0, 130),           -- Ink-indigo badge
    ["Creative Pro"] = Color3.fromRGB(0, 128, 128),       -- Watercolor-teal badge
    ["Studio Ace"] = Color3.fromRGB(0, 128, 0),           -- Acrylic-green badge
    ["Canvas Champion"] = Color3.fromRGB(205, 127, 50),   -- Gold-bronze badge
    ["Master Artist"] = Color3.fromRGB(255, 215, 0),      -- Polished-gold badge
    ["Art Grandmaster"] = Color3.fromRGB(255, 145, 145),  -- Rose-gold badge
    ["Legendary Creator"] = Color3.fromRGB(255, 0, 255)   -- Animated rainbow badge (using magenta as placeholder)
}

-- Store BillboardGuis for each player
local playerBillboards = {}

-- Function to determine player rank based on points
local function getPlayerRank(points)
    if not points or type(points) ~= "number" then
        return nil
    end
    
    if points >= 2081 then return "Legendary Creator"
    elseif points >= 1581 then return "Art Grandmaster"
    elseif points >= 1181 then return "Master Artist"
    elseif points >= 881 then return "Canvas Champion"
    elseif points >= 631 then return "Studio Ace"
    elseif points >= 421 then return "Creative Pro"
    elseif points >= 251 then return "Art Adept"
    elseif points >= 121 then return "Sketch Star"
    elseif points >= 31 then return "Rookie Artist"
    else return "Beginner"
    end
end

-- Function to create a BillboardGui for a player
local function createPlayerBillboard(player, character)
    -- Check if character exists
    if not character then return end
    
    -- Get the head to attach the BillboardGui to
    local head = character:FindFirstChild("Head")
    if not head then return end
    
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
    
    -- Get the player's rank
    local rank = getPlayerRank(points)
    if not rank then return end
    
    -- Get the BillboardGui for this player
    local billboardData = playerBillboards[player.UserId]
    if not billboardData then return end
    
    -- Update the rank label with points included
    billboardData.rankLabel.Text = string.format("%s (%s)", rank, tostring(points))
    billboardData.rankLabel.TextColor3 = RANK_COLORS[rank] or Color3.fromRGB(255, 255, 255)
end

-- Function to handle when a player's character is added
local function onCharacterAdded(player, character)
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
        onCharacterAdded(player, player.Character)
    end
end

-- Function to handle when a player is removed from the game
local function onPlayerRemoving(player)
    onCharacterRemoved(player)
end

-- Function to handle when player data is updated
local function onPlayerDataUpdated(playerData)
    if not playerData then return end
    
    -- Update the BillboardGui for the local player
    updatePlayerBillboard(LocalPlayer, playerData)
end

-- Connect to the PlayerDataUpdated event
PlayerDataUpdatedEvent.OnClientEvent:Connect(onPlayerDataUpdated)

-- Connect to the PlayerAdded and PlayerRemoving events
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Initialize existing players
for _, player in ipairs(Players:GetPlayers()) do
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
