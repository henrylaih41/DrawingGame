-- GameManager.server.lua
-- Manages the overall game flow and states

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Get existing remote events folder
local EventsFolder = ReplicatedStorage:WaitForChild("Events")

-- Get all required events with WaitForChild
local GameStateChangedEvent = EventsFolder:WaitForChild("GameStateChanged")
local UpdateLobbyPlayersEvent = EventsFolder:WaitForChild("UpdateLobbyPlayers")
local PlayerReadyEvent = EventsFolder:WaitForChild("PlayerReady")
local StartGameEvent = EventsFolder:WaitForChild("StartGame")
local GameCountdownEvent = EventsFolder:WaitForChild("GameCountdown")
local SubmitDrawingEvent = EventsFolder:WaitForChild("SubmitDrawing")
local DrawingsReceivedEvent = EventsFolder:WaitForChild("DrawingsReceived")
local SubmitVoteEvent = EventsFolder:WaitForChild("SubmitVote")

-- Game constants
local MAX_PLAYERS = 8
local COUNTDOWN_TIME = 1
local DRAWING_TIME = 5 -- 3 minutes
local DEBUG_ENABLED = true -- Debug flag to enable/disable debug messages
local VOTING_TIME = 30 -- 30 seconds for voting

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

-- Add this after the game constants
local playerDrawings = {} -- Store player drawings for voting phase

-- Add these variables for voting
local playerVotes = {} -- Store player votes (who voted for whom)
local voteResults = {} -- Tally of votes per drawing

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
    for _, player in ipairs(lobbyPlayers) do
        GameStateChangedEvent:FireClient(player, currentState)
    end
end

-- Function to update lobby player list for all clients
local function updateLobbyPlayers()
    -- Send the updated list to all lobby players
    UpdateLobbyPlayersEvent:FireAllClients(lobbyPlayers, hostPlayer, readyPlayers)
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
    GameStateChangedEvent:FireClient(player, currentState)
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
PlayerReadyEvent.OnServerEvent:Connect(function(player, isReady)
    debugPrint("Player %s ready status changed to: %s", player.Name, tostring(isReady))
    if readyPlayers[player.UserId] ~= nil then
        readyPlayers[player.UserId] = isReady
        updateLobbyPlayers()
    end
end)

-- Handle game start request (from host)
StartGameEvent.OnServerEvent:Connect(function(player)
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
                GameCountdownEvent:FireAllClients(i, GameState.COUNTDOWN)
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
                GameCountdownEvent:FireAllClients(i, GameState.DRAWING)
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
            currentState = GameState.VOTING
            broadcastGameState()

            -- Prepare drawings for voting
            local drawingsForVoting = {}
            for userId, imageData in pairs(playerDrawings) do
                table.insert(drawingsForVoting, {
                    playerId = userId,
                    imageData = imageData
                })
            end

            -- Send drawings to all clients
            debugPrint("Sending " .. #drawingsForVoting .. " drawings to clients for voting")
            for _, player in ipairs(lobbyPlayers) do
                DrawingsReceivedEvent:FireClient(player, drawingsForVoting)
            end

            -- Reset voting variables
            playerVotes = {}
            voteResults = {}

            -- Start voting time countdown
            for i = VOTING_TIME, 0, -1 do
                if i % 5 == 0 or i <= 10 then -- Less frequent debug prints
                    debugPrint("Voting time remaining: %d seconds", i)
                end
                GameCountdownEvent:FireAllClients(i, GameState.VOTING)
                wait(1)
                
                -- Notify players when time is running low
                if i == 10 then -- 10 second warning
                    debugPrint("10 seconds remaining for voting")
                end
            end

            -- Give a small grace period for final votes
            debugPrint("Voting time complete, tallying results")
            wait(2)

            -- Tally votes
            local winningPlayerId = nil
            local highestVotes = 0

            for votedId, count in pairs(voteResults) do
                debugPrint("Player %s received %d votes", votedId, count)
                if count > highestVotes then
                    highestVotes = count
                    winningPlayerId = votedId
                end
            end

            -- Announce winner
            if winningPlayerId then
                local winnerName = "Unknown"
                for _, player in ipairs(lobbyPlayers) do
                    if tostring(player.UserId) == winningPlayerId then
                        winnerName = player.Name
                        break
                    end
                end
                debugPrint("Winner is %s with %d votes", winnerName, highestVotes)
            else
                debugPrint("No winner determined (no votes)")
            end

            -- Transition to results phase
            debugPrint("Transitioning to RESULTS state")
            currentState = GameState.RESULTS
            broadcastGameState()

            -- Show results for 10 seconds
            wait(10)
            
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

-- Handle drawing submissions
SubmitDrawingEvent.OnServerEvent:Connect(function(player, imageData)
    if currentState == GameState.DRAWING or currentState == GameState.COUNTDOWN then
        -- Store the player's drawing
        playerDrawings[player.UserId] = imageData
        debugPrint("Received drawing from player: %s", player.Name)
        print(imageData)
        print("Received drawing from player: " .. player.Name)
    else
        debugPrint("Ignoring drawing from %s - received outside of drawing phase (current state: %s)", 
            player.Name, currentState)
    end
end)

-- Handle votes
SubmitVoteEvent.OnServerEvent:Connect(function(player, votedPlayerId)
    if currentState ~= GameState.VOTING then
        debugPrint("Ignoring vote from %s - received outside of voting phase", player.Name)
        return
    end
    
    -- Check if player has already voted
    if playerVotes[player.UserId] then
        debugPrint("Player %s already voted", player.Name)
        return
    end
    
    -- Record the vote
    playerVotes[player.UserId] = votedPlayerId
    
    -- Tally the vote
    local votedId = tostring(votedPlayerId)
    voteResults[votedId] = (voteResults[votedId] or 0) + 1
    
    debugPrint("Player %s voted for %s", player.Name, votedId)
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
    GameStateChangedEvent:FireClient(player, currentState)
end

-- Update lobby players list for all after processing existing players
if #lobbyPlayers > 0 then
    updateLobbyPlayers()
end
debugPrint("Done processing existing players when script starts")
