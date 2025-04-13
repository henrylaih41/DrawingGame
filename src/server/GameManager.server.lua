-- GameManager.server.lua
-- Manages the overall game flow and states

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Get existing remote events folder
local Events = ReplicatedStorage:WaitForChild("Events")

-- Game constants
local MAX_PLAYERS = 8
local COUNTDOWN_TIME = 1
local DRAWING_TIME = 180 -- 3 minutes
local DEBUG_ENABLED = true -- Debug flag to enable/disable debug messages

-- Game state tracking
local GameState = {
    LOBBY = "LOBBY",
    COUNTDOWN = "COUNTDOWN",
    DRAWING = "DRAWING",
    VOTING = "VOTING",
    RESULTS = "RESULTS"
}

local currentState = GameState.LOBBY
local lobbyPlayers = {}
local hostPlayer = nil
local readyPlayers = {}

-- Add these lines to the top of the file, where other events are defined
local SubmitDrawingEvent = Instance.new("RemoteEvent")
SubmitDrawingEvent.Name = "SubmitDrawing"
SubmitDrawingEvent.Parent = Events

-- Add this after the game constants
local playerDrawings = {} -- Store player drawings for voting phase

-- Debug print function that only outputs when debugging is enabled
local function debugPrint(message, ...)
    if DEBUG_ENABLED then
        local formattedArgs = {...}
        for i, arg in ipairs(formattedArgs) do
            if type(arg) == "table" then
                formattedArgs[i] = table.concat(arg, ", ")
            else
                formattedArgs[i] = tostring(arg)
            end
        end
        
        local finalMessage = "[DEBUG] " .. message
        if #formattedArgs > 0 then
            print(finalMessage:format(unpack(formattedArgs)))
        else
            print(finalMessage)
        end
    end
end

-- Function to broadcast the current game state to all clients
local function broadcastGameState()
    debugPrint("Broadcasting game state: %s", currentState)
    Events.GameStateChanged:FireAllClients(currentState)
end

-- Function to update lobby player list for all clients
local function updateLobbyPlayers()
    debugPrint("Updating lobby players. Count: %d, Host: %s", #lobbyPlayers, hostPlayer and hostPlayer.Name or "None")
    Events.UpdateLobbyPlayers:FireAllClients(lobbyPlayers, hostPlayer, readyPlayers)
end

-- Handle player joining
Players.PlayerAdded:Connect(function(player)
    debugPrint("Player joined: %s", player.Name)
    -- If this is the first player, they become the host
    if #lobbyPlayers == 0 then
        hostPlayer = player
        debugPrint("Set host player to: %s", player.Name)
    end
    
    table.insert(lobbyPlayers, player)
    readyPlayers[player.UserId] = false
    
    -- Update all clients with the new player list
    updateLobbyPlayers()
    
    -- Tell the new player the current game state
    debugPrint("Sending current game state to new player: %s", currentState)
    Events.GameStateChanged:FireClient(player, currentState)
end)


-- Handle player leaving
Players.PlayerRemoving:Connect(function(player)
    debugPrint("Player leaving: %s", player.Name)
    -- Remove player from the lobby list
    for i, p in ipairs(lobbyPlayers) do
        if p == player then
            table.remove(lobbyPlayers, i)
            debugPrint("Removed player from lobby list")
            break
        end
    end
    
    -- Clear ready status
    readyPlayers[player.UserId] = nil
    debugPrint("Cleared ready status for player")
    
    -- If the host left, assign a new host
    if hostPlayer == player and #lobbyPlayers > 0 then
        hostPlayer = lobbyPlayers[1]
        debugPrint("Host left, new host is: %s", hostPlayer.Name)
    end
    
    -- Update all clients
    updateLobbyPlayers()
end)

-- Handle player ready status changes
Events.PlayerReady.OnServerEvent:Connect(function(player, isReady)
    debugPrint("Player %s ready status changed to: %s", player.Name, tostring(isReady))
    if readyPlayers[player.UserId] ~= nil then
        readyPlayers[player.UserId] = isReady
        updateLobbyPlayers()
    end
end)

-- Handle game start request (from host)
Events.StartGame.OnServerEvent:Connect(function(player)
    debugPrint("Received start game request from player: %s", player.Name)
    -- Verify the request is from the host and we're in LOBBY state
    if player == hostPlayer and currentState == GameState.LOBBY then
        debugPrint("Request validated: player is host and game is in LOBBY state")
        -- Check if we have at least 1 player and all are ready
        local allReady = true
        local readyCount = 0
        
        for _, ready in pairs(readyPlayers) do
            if ready then
                readyCount = readyCount + 1
            else
                allReady = false
                break
            end
        end
        
        debugPrint("Ready check: %d players ready, all ready: %s", readyCount, tostring(allReady))
        
        -- Allow starting with at least 1 ready player
        if readyCount >= 1 and allReady then
            debugPrint("Game starting: Transitioning to COUNTDOWN state")
            -- Start the game countdown
            currentState = GameState.COUNTDOWN
            broadcastGameState()
            
            -- Start countdown
            for i = COUNTDOWN_TIME, 1, -1 do
                debugPrint("Countdown: %d", i)
                Events.GameCountdown:FireAllClients(i)
                wait(1) -- Wait 1 second
            end
            
            -- Transition to drawing phase
            debugPrint("Countdown complete: Transitioning to DRAWING state")
            currentState = GameState.DRAWING
            broadcastGameState()
            
            -- Clear previous drawings
            playerDrawings = {}
            debugPrint("Cleared previous drawings")
            
            -- Add this code for drawing time countdown:
            for i = DRAWING_TIME, 0, -1 do
                if i % 30 == 0 or i <= 10 then -- Only debug print at intervals to avoid spam
                    debugPrint("Drawing time remaining: %d seconds", i)
                end
                Events.GameCountdown:FireAllClients(i, "DRAWING")
                wait(1)
                
                -- Notify players when time is running low
                if i == 60 then -- 1 minute warning
                    debugPrint("1 minute warning")
                    -- Optional: add specific notification
                elseif i == 30 then -- 30 second warning
                    debugPrint("30 seconds warning")
                    -- Optional: add specific notification
                elseif i == 10 then -- 10 second warning
                    debugPrint("10 seconds warning")
                    -- Optional: add specific notification
                end
            end
            
            -- Give a small grace period for final submissions
            debugPrint("Drawing time complete, waiting 3 seconds grace period")
            wait(3)
            
            -- Transition to voting phase
            debugPrint("Transitioning to VOTING state")
            currentState = GameState.VOTING
            broadcastGameState()
            
            -- Optional: Print how many drawings were submitted
            local drawingCount = 0
            for _, _ in pairs(playerDrawings) do
                drawingCount = drawingCount + 1
            end
            debugPrint("Total drawings submitted: %d out of %d players", drawingCount, #lobbyPlayers)
            print("Total drawings submitted: " .. drawingCount .. " out of " .. #lobbyPlayers .. " players")
            
            -- Return to lobby
            debugPrint("Transitioning back to LOBBY state")
            currentState = GameState.LOBBY
            -- Reset ready status
            for userId, _ in pairs(readyPlayers) do
                readyPlayers[userId] = false
            end
            debugPrint("Reset all ready statuses")
            
            broadcastGameState()
            updateLobbyPlayers()
        end
    end
end)

-- Add this to handle drawing submissions
SubmitDrawingEvent.OnServerEvent:Connect(function(player, imageData)
    if currentState == GameState.DRAWING or currentState == GameState.COUNTDOWN then
        -- Store the player's drawing
        playerDrawings[player.UserId] = imageData
        debugPrint("Received drawing from player: %s", player.Name)
        print("Received drawing from player: " .. player.Name)
    else
        debugPrint("Ignoring drawing from %s - received outside of drawing phase (current state: %s)", 
            player.Name, currentState)
    end
end) 

debugPrint("Processing existing players when script starts")
-- Process existing players when script starts
for _, player in ipairs(Players:GetPlayers()) do
    debugPrint("Processing existing player: %s", player.Name)
    -- If this is the first player, they become the host
    if #lobbyPlayers == 0 then
        hostPlayer = player
        debugPrint("Set host player to: %s", player.Name)
    end
    
    table.insert(lobbyPlayers, player)
    readyPlayers[player.UserId] = false
    
    -- Tell the existing player the current game state
    debugPrint("Sending current game state to existing player: %s", currentState)
    Events.GameStateChanged:FireClient(player, currentState)
end

-- Update lobby players list for all after processing existing players
if #lobbyPlayers > 0 then
    updateLobbyPlayers()
end
debugPrint("Done processing existing players when script starts")
