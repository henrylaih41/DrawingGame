local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local GameConfig = require(ReplicatedStorage.Modules.GameData.GameConfig)
local RankConfig = require(ReplicatedStorage.Modules.GameData.RankConfig)
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local RankProgressScreen = PlayerGui:WaitForChild("RankProgressScreen")
-- Get references to events
local Events = ReplicatedStorage:WaitForChild("Events")
local PlayerDataUpdatedEvent = Events:WaitForChild("PlayerDataUpdated")

-- Constants for BillboardGui appearance
local BILLBOARD_SIZE = UDim2.new(4, 0, 1.5, 0)
local BILLBOARD_OFFSET = Vector3.new(0, 2, 0)
local NAME_TEXT_SIZE = UDim2.new(1, 0, 0.5, 0)
local RANK_TEXT_SIZE = UDim2.new(1, 0, 0.3, 0)

-- Store BillboardGuis for each player
local playerBillboards = {}
local rankBars = {}
local TopLevelContainer = RankProgressScreen:WaitForChild("TopLevelContainer")
local Header = TopLevelContainer:WaitForChild("Header")
local PlayerInfo = Header:WaitForChild("PlayerInfo")
local PlayerRankLabel = PlayerInfo:WaitForChild("PlayerRank")
local playerPointsLabel = PlayerInfo:WaitForChild("PlayerPoints")
local ProgressContainer = Header:WaitForChild("ProgressContainer")
local ProgressBar = ProgressContainer:WaitForChild("ProgressBar")
local ProgressBarFill = ProgressBar:WaitForChild("Fill")
local ProgressLabel = ProgressContainer:WaitForChild("ProgressLabel")
local RanksScrollFrame = TopLevelContainer:WaitForChild("RanksScrollFrame")
local RanksContainer = RanksScrollFrame:WaitForChild("RanksContainer")
local CloseButton = Header:WaitForChild("CloseButton")

local cachedPlayerData = nil

-- Create the rank data structure
local RANKS = {
    {tier = 1, name = "Beginner", minPoints = 0, maxPoints = 30, color = Color3.fromRGB(240, 240, 240), icon = "📄"},
    {tier = 2, name = "Rookie Artist", minPoints = 31, maxPoints = 120, color = Color3.fromRGB(128, 128, 128), icon = "✏️"},
    {tier = 3, name = "Sketch Star", minPoints = 121, maxPoints = 250, color = Color3.fromRGB(135, 206, 235), icon = "⭐"},
    {tier = 4, name = "Art Adept", minPoints = 251, maxPoints = 420, color = Color3.fromRGB(75, 0, 130), icon = "🎨"},
    {tier = 5, name = "Creative Pro", minPoints = 421, maxPoints = 630, color = Color3.fromRGB(64, 224, 208), icon = "🖌️"},
    {tier = 6, name = "Studio Ace", minPoints = 631, maxPoints = 880, color = Color3.fromRGB(50, 205, 50), icon = "🎭"},
    {tier = 7, name = "Canvas Champion", minPoints = 881, maxPoints = 1180, color = Color3.fromRGB(184, 134, 11), icon = "🏆"},
    {tier = 8, name = "Master Artist", minPoints = 1181, maxPoints = 1580, color = Color3.fromRGB(255, 215, 0), icon = "👑"},
    {tier = 9, name = "Art Grandmaster", minPoints = 1581, maxPoints = 2080, color = Color3.fromRGB(255, 182, 193), icon = "🌟"},
    {tier = 10, name = "Legendary Creator", minPoints = 2081, maxPoints = math.huge, color = Color3.fromRGB(255, 105, 180), icon = "🌈", isAnimated = true}
}

-- Function to get rank by points
local function getRankByPoints(points)
    for _, rank in ipairs(RANKS) do
        if points >= rank.minPoints and points <= rank.maxPoints then
            return rank
        end
    end
    return RANKS[1] -- Default to beginner if something goes wrong
end

-- Function to update player info display
local function updatePlayerInfo(playerData)
    if not playerData then return end
    
    local points = playerData.TotalPoints or 0
    local currentRank = getRankByPoints(points)
    
    -- Update player rank and points
    PlayerRankLabel.Text = currentRank.name
    PlayerRankLabel.TextColor3 = currentRank.color
    playerPointsLabel.Text = tostring(points) .. " Points"
    
    -- Calculate progress to next rank
    local nextRank = RANKS[currentRank.tier + 1]
    local progressPercent = 0
    local progressText = ""
    
    if nextRank then
        local pointsInCurrentRank = points - currentRank.minPoints
        local pointsNeededForNextRank = nextRank.minPoints - currentRank.minPoints
        progressPercent = math.clamp(pointsInCurrentRank / pointsNeededForNextRank, 0, 1)
        local pointsToNext = nextRank.minPoints - points
        progressText = pointsToNext .. " points to " .. nextRank.name
    else
        progressPercent = 1
        progressText = "Maximum rank achieved!"
    end
    
    -- Update progress bar with animation
    local fillTween = TweenService:Create(
        ProgressBarFill,
        TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Size = UDim2.new(progressPercent, 0, 1, 0)}
    )

    fillTween:Play()
    
    ProgressLabel.Text = progressText
    
    -- Highlight current rank
    for i, rankBar in ipairs(rankBars) do
        if i == currentRank.tier then
            rankBar.BackgroundColor3 = GameConfig.SELECTED_COLOR
            rankBar.BorderSizePixel = 2
            rankBar.BorderColor3 = currentRank.color
        else
            rankBar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            rankBar.BorderSizePixel = 0
        end
    end
end

-- Function to toggle screen visibility
local function toggleRankScreen()
    TopLevelContainer.Visible = not TopLevelContainer.Visible

    -- This would play the animation
    if RankProgressScreen.Visible and cachedPlayerData then
        updatePlayerInfo(cachedPlayerData)
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
    createPlayerBillboard(player, character)
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
local function onPlayerDataUpdated(data)
    local player = data.player
    local playerData = data.playerData

    if not playerData then return end

    -- Update the player's rank info
    if player == LocalPlayer then
        updatePlayerInfo(playerData)
        cachedPlayerData = playerData
    end
    
    updatePlayerBillboard(player, playerData)
end

local function init()
    -- Connect to the PlayerDataUpdated event
    PlayerDataUpdatedEvent.OnClientEvent:Connect(onPlayerDataUpdated)

    -- Connect to the PlayerAdded and PlayerRemoving events
    Players.PlayerAdded:Connect(onPlayerAdded)
    Players.PlayerRemoving:Connect(onPlayerRemoving)

    -- Initialize existing players
    for _, player in ipairs(Players:GetPlayers()) do
        onPlayerAdded(player)
    end

    -- Request all player data from the server
    Events.RequestAllPlayerData:FireServer()

    -- Ranks 
    for _, child in RanksContainer:GetChildren() do
        if child:IsA("Frame") then
            table.insert(rankBars, child)
        end
    end

    CloseButton.Activated:Connect(toggleRankScreen)
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

init()

-- Return cleanup function
return cleanup

