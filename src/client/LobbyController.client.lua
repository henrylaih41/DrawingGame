-- LobbyController.client.lua
-- Handles client-side lobby functionality

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Events = ReplicatedStorage:WaitForChild("Events")
local PlayerReadyEvent = Events:WaitForChild("PlayerReady")
local StartGameEvent = Events:WaitForChild("StartGame") 
local GameCountdownEvent = Events:WaitForChild("GameCountdown")
local GameStateChangedEvent = Events:WaitForChild("GameStateChanged")
local UpdateLobbyPlayersEvent = Events:WaitForChild("UpdateLobbyPlayers")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for UI to be loaded by the user
local lobbyUI = playerGui:WaitForChild("LobbyUI")
local playerListFrame = lobbyUI:WaitForChild("PlayerList")
local readyButton = lobbyUI:WaitForChild("ReadyButton")
local startGameButton = lobbyUI:WaitForChild("StartGameButton")
local countdownLabel = lobbyUI:WaitForChild("CountdownLabel")

-- Variables to track state
local isReady = false
local isHost = false
local currentGameState = "MAIN_MENU"

-- Function to update the lobby UI based on received data
local function updateLobbyUI(playersList, hostPlayer, readyPlayers)
    print("updateLobbyUI called with", #playersList, "players")
    if not playersList or #playersList == 0 then
        warn("Player list is empty or nil!")
    end
    
    if not hostPlayer then
        warn("Host player is nil!")
    end
    
    print("Ready players data:", readyPlayers)
    
    -- Clear existing player entries
    for _, child in ipairs(playerListFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Update player list
    for i, plr in ipairs(playersList) do
        print("Creating entry for player:", plr.Name, "- UserId:", plr.UserId)
        local playerEntry = Instance.new("Frame")
        playerEntry.Name = "Player_" .. plr.Name
        playerEntry.Size = UDim2.new(1, 0, 0, 30)
        playerEntry.Position = UDim2.new(0, 0, 0, (i-1) * 35)
        playerEntry.BackgroundColor3 = Color3.fromRGB(40, 40, 40) -- Added for visibility
        playerEntry.BorderSizePixel = 1 -- Added for visibility
        playerEntry.Parent = playerListFrame
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Name = "NameLabel"
        nameLabel.Size = UDim2.new(0.7, 0, 1, 0)
        nameLabel.Position = UDim2.new(0, 5, 0, 0)
        nameLabel.Text = plr.Name .. (plr == hostPlayer and " (Host)" or "")
        nameLabel.TextColor3 = plr == hostPlayer and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(255, 255, 255)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Parent = playerEntry
        print("Created name label with text:", nameLabel.Text)
        
        local statusLabel = Instance.new("TextLabel")
        statusLabel.Name = "StatusLabel"
        statusLabel.Size = UDim2.new(0.3, -5, 1, 0)
        statusLabel.Position = UDim2.new(0.7, 0, 0, 0)
        
        -- Fix: Check ready status properly by comparing as strings to avoid type issues
        local userId = tostring(plr.UserId)
        local isPlayerReady = false
        
        if readyPlayers then
            -- Check both as direct key and as string key to handle any type conversion issues
            if readyPlayers[plr.UserId] ~= nil then
                isPlayerReady = readyPlayers[plr.UserId]
            elseif readyPlayers[userId] ~= nil then
                isPlayerReady = readyPlayers[userId]
            end
        end
        
        print("Player", plr.Name, "Ready status:", isPlayerReady)
        
        statusLabel.Text = isPlayerReady and "Ready" or "Not Ready" 
        statusLabel.TextColor3 = isPlayerReady and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
        statusLabel.BackgroundTransparency = 1
        statusLabel.Parent = playerEntry
    end
    
    -- Update host status
    isHost = (hostPlayer == player)
    print("Player is host:", isHost)
    
    -- Show/hide start game button based on host status
    startGameButton.Visible = isHost
end

-- Handle ready button click
readyButton.MouseButton1Click:Connect(function()
    isReady = not isReady
    readyButton.Text = isReady and "Unready" or "Ready"
    PlayerReadyEvent:FireServer(isReady)
end)

-- Handle start game button click (only for host)
startGameButton.MouseButton1Click:Connect(function()
    if isHost and currentGameState == "LOBBY" then
        StartGameEvent:FireServer()
    end
end)

-- Handle lobby players update from server
UpdateLobbyPlayersEvent.OnClientEvent:Connect(function(playersList, hostPlayer, readyPlayers)
    print("Received UpdateLobbyPlayers event with data:")
    print("  - Players count:", playersList and #playersList or "nil")
    print("  - Host player:", hostPlayer and hostPlayer.Name or "nil")
    
    -- Debug ready players information
    if readyPlayers then
        print("  - Ready players data received")
        for userId, isReady in pairs(readyPlayers) do
            print("    Player ID:", userId, "Ready:", isReady)
        end
    else
        print("  - Ready players is nil")
    end
    
    if not playersList then
        warn("ERROR: Received nil playersList from server!")
        return
    end
    
    updateLobbyUI(playersList, hostPlayer, readyPlayers)
end)

-- Handle game state changes
GameStateChangedEvent.OnClientEvent:Connect(function(stateData)
    local newState = stateData.state
    currentGameState = newState
    
    -- Update UI based on game state
    if newState == "LOBBY" then
        -- TODO: Use Visible instead of Enabled for ScreenGUI
        lobbyUI.Enabled = true  -- Using Enabled for ScreenGUI
        isReady = false
        readyButton.Text = "Ready"
        countdownLabel.Visible = false
    elseif newState == "COUNTDOWN" then
        countdownLabel.Visible = true
    else
        -- TODO: Use Visible instead of Enabled for ScreenGUI
        lobbyUI.Enabled = false  -- Using Enabled for ScreenGUI
    end
end)

-- Handle countdown updates
GameCountdownEvent.OnClientEvent:Connect(function(count)
    countdownLabel.Text = "Game starting in " .. count .. "..."
end)