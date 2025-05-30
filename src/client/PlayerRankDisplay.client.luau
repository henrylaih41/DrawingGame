local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
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
local BILLBOARD_OFFSET = Vector3.new(0, 2, 0) -- Increased offset to make room for supporter title
local NAME_TEXT_SIZE = UDim2.new(1, 0, 0.5, 0) -- Adjusted size
local RANK_TEXT_SIZE = UDim2.new(1, 0, 0.3, 0) -- Adjusted size
local SUPPORTER_TEXT_SIZE = UDim2.new(1, 0, 0.2, 0) -- New size for supporter title

-- Supporter Title Configuration
local SUPPORTER_TITLE_COLOR1 = Color3.fromRGB(255, 215, 0) -- Gold

-- Store BillboardGuis for each player
local playerBillboards = {}
local playerCharacters = {} -- Store characters waiting for player data
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

-- Function to get rank by points
local function getRankByPoints(points)
    return RankConfig.getRankForPoints(points) or RankConfig.getRankByIndex(1)
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
    local currentIndex = RankConfig.getRankIndexForPoints(points) or 1
    local nextRank = RankConfig.getRankByIndex(currentIndex + 1)
    local progressPercent = 0
    local progressText = ""

    if nextRank then
        local pointsInCurrentRank = points - currentRank.threshold
        local pointsNeededForNextRank = nextRank.threshold - currentRank.threshold
        progressPercent = math.clamp(pointsInCurrentRank / pointsNeededForNextRank, 0, 1)
        local pointsToNext = nextRank.threshold - points
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

        local rankInfo = RankConfig.getRankByIndex(i)
        for _, child in rankBar:GetChildren() do
            if child:IsA("TextLabel") then
                child.TextColor3 = rankInfo.color
            end

            if child.Name == "PointsRange" then
                local rank_i = RankConfig.getRankByIndex(i)
                local rank_i_1 = RankConfig.getRankByIndex(i + 1)

                local threshold_i = rank_i.threshold
                local threshold_i_1 = "∞"

                if rank_i_1 then
                    threshold_i_1 = rank_i_1.threshold - 1
                end 

                child.Text = tostring(threshold_i) .. " - " .. tostring(threshold_i_1) .. " Points"
            end

            if child.Name == "MaximumLikesLabel" then
                child.Text = "MaximumLikes: " .. tostring(rankInfo.maximumLikes)
            end

            if child.Name == "GallerySizeLabel" then
                child.Text = "GallerySize: " .. tostring(rankInfo.gallerySize)
            end
        end

        if i == currentIndex then
            rankBar.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
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
    if TopLevelContainer.Visible and cachedPlayerData then
        updatePlayerInfo(cachedPlayerData)
    end
end

-- Function to create animated supporter title
local function createSupporterTitle(frame)
    -- Create supporter title label
    local supporterLabel = Instance.new("TextLabel")
    supporterLabel.Name = "SupporterLabel"
    supporterLabel.Size = SUPPORTER_TEXT_SIZE
    supporterLabel.Position = UDim2.new(0, 0, 0.05, 0) -- Position above name
    supporterLabel.BackgroundTransparency = 1
    supporterLabel.TextColor3 = SUPPORTER_TITLE_COLOR1
    supporterLabel.TextStrokeTransparency = 0
    supporterLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    supporterLabel.Font = Enum.Font.GothamBold
    supporterLabel.TextScaled = true
    supporterLabel.Text = "⭐ SUPPORTER ⭐"
    supporterLabel.Parent = frame
    
    -- Store animation cleanup
    return {
        label = supporterLabel,
    }
end

-- Function to create a BillboardGui for a player
local function createPlayerBillboard(player, character, isSupporter)

    -- Check if the player already has a BillboardGui
    if playerBillboards[player.UserId] then
        return
    end

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
    nameLabel.Position = UDim2.new(0, 0, 0.25, 0) -- Adjusted position
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
    rankLabel.Position = UDim2.new(0, 0, 0.75, 0) -- Adjusted position
    rankLabel.BackgroundTransparency = 1
    rankLabel.TextStrokeTransparency = 0.5
    rankLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    rankLabel.Font = Enum.Font.GothamBold
    rankLabel.TextScaled = true
    rankLabel.Text = ""
    rankLabel.Parent = frame
    
    -- Create supporter title if applicable
    local supporterData = nil
    if isSupporter then
        supporterData = createSupporterTitle(frame)
    end
    
    -- Parent the BillboardGui to the character
    billboardGui.Parent = character
    
    -- Store the BillboardGui
    playerBillboards[player.UserId] = {
        billboard = billboardGui,
        nameLabel = nameLabel,
        rankLabel = rankLabel,
        supporterData = supporterData
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
    if not billboardData then 
        -- If no billboard exists but character exists, create one
        if player.Character then
            createPlayerBillboard(player, player.Character, playerData.isSupporter)
            billboardData = playerBillboards[player.UserId]
            if not billboardData then return end
        else
            return
        end
    end

    -- Update the rank label with points included
    billboardData.rankLabel.Text = string.format("%s (%s)", rankInfo.name, tostring(points))
    billboardData.rankLabel.TextColor3 = rankInfo.color or Color3.fromRGB(255, 255, 255)
    
    -- Update supporter status
    if playerData.isSupporter and not billboardData.supporterData then
        -- Player became a supporter, add the title
        billboardData.supporterData = createSupporterTitle(billboardData.billboard.Container)
    elseif not playerData.isSupporter and billboardData.supporterData then
        -- Player is no longer a supporter, remove the title
        if billboardData.supporterData.label then
            billboardData.supporterData.label:Destroy()
        end
        billboardData.supporterData = nil
    end
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

    -- Store the character and wait for player data
    playerCharacters[player.UserId] = character
end

-- Function to handle when a player's character is removed
local function onCharacterRemoved(player)
    -- Clean up the BillboardGui for this player
    local billboardData = playerBillboards[player.UserId]
    if billboardData then
        -- Destroy billboard
        if billboardData.billboard then
            billboardData.billboard:Destroy()
        end
    end
    
    -- Remove the player from our tracking tables
    playerBillboards[player.UserId] = nil
    playerCharacters[player.UserId] = nil
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
    
    -- Check if we have a character waiting for this player's data
    local character = playerCharacters[player.UserId] or player.Character
    if character then
        updatePlayerBillboard(player, playerData)
    end
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
    
    -- Clear the tracking tables
    playerBillboards = {}
    playerCharacters = {}
end

init()

-- Return cleanup function
return cleanup

