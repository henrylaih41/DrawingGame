-- GameManager.server.lua
-- Manages the overall game flow and states


local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CanvasDraw = require(ReplicatedStorage.Modules.Canvas.CanvasDraw)

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
local ShowResultsEvent = EventsFolder:WaitForChild("ShowResults")

-- Game constants
local MAX_PLAYERS = 8
local COUNTDOWN_TIME = 1
local DRAWING_TIME = 5 -- 3 minutes
local DEBUG_ENABLED = true -- Debug flag to enable/disable debug messages
local VOTING_TIME = 30 -- 30 seconds for voting

-- Add GameMode definition
local GameMode = {
    SINGLE_PLAYER = "SINGLE_PLAYER",
    MULTIPLAYER = "MULTIPLAYER"
}
local currentGameMode = GameMode.SINGLE_PLAYER -- Default to multiplayer, can be changed later (e.g., by host)

-- Game state tracking
local GameState = {
    LOBBY = "LOBBY",
    COUNTDOWN = "COUNTDOWN",
    DRAWING = "DRAWING",
    GRADING = "GRADING",
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
local playerScores = {} -- Store player scores and feedback (single-player)

-- Add this near the top with other services
local BackendService = require(ReplicatedStorage.Modules.Services.BackendService)

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

-- Function to transition to a new game state
local function transitionToState(newState)
    debugPrint("Transitioning from %s to %s", currentState, newState)
    currentState = newState
    broadcastGameState() -- Inform clients about the state change

    -- Call the function corresponding to the new state
    if newState == GameState.COUNTDOWN then
        -- Countdown logic is handled within StartGameEvent for now
        -- Or could be moved to its own function if needed
    elseif newState == GameState.DRAWING then
        -- Drawing logic is handled within StartGameEvent for now
        -- Or could be moved to its own function if needed
    elseif newState == GameState.GRADING then
        -- Grading logic will be triggered after drawing in single-player
        -- This state primarily involves waiting for backend processing
        debugPrint("Entered GRADING state. Waiting for backend analysis.")
        -- Actual grading calls happen after drawing phase finishes
    elseif newState == GameState.VOTING then
        -- Voting logic is handled within StartGameEvent for now
        -- Or could be moved to its own function if needed
    elseif newState == GameState.RESULTS then
        -- Results logic is handled within StartGameEvent for now
        -- Or could be moved to its own function if needed
    elseif newState == GameState.LOBBY then
        -- Reset ready status when returning to lobby
        for userId, _ in pairs(readyPlayers) do
            readyPlayers[userId] = false
        end
        debugPrint("Reset all ready statuses for LOBBY")
        updateLobbyPlayers() -- Update clients with reset ready status
    end
end

-- Handle game start request (from host)
StartGameEvent.OnServerEvent:Connect(function(player)
    debugPrint("Received start game request from player: %s", player.Name)
    if player ~= hostPlayer or currentState ~= GameState.LOBBY then
        debugPrint("Start game request denied (not host or not in lobby)")
        return -- Only host can start, and only from Lobby
    end

    -- Check readiness (Allow starting if host is the only player and ready)
    local allReady = true
    local readyCount = 0
    local totalPlayers = #lobbyPlayers

    for p_userId, isReady in pairs(readyPlayers) do
        -- Ensure the player is still in the lobby before checking readiness
        local playerInLobby = false
        for _, lobby_p in ipairs(lobbyPlayers) do
            if lobby_p.UserId == p_userId then
                playerInLobby = true
                break
            end
        end

        if playerInLobby then
            if isReady then
                readyCount = readyCount + 1
            else
                -- If anyone isn't ready (and it's not just the host alone), prevent start
                if totalPlayers > 1 then 
                    allReady = false
                    debugPrint("Player %s is not ready.", p_userId)
                    break
                end
            end
        end
    end

    -- Start game if conditions met (at least 1 player, and all are ready if multiplayer)
    if readyCount >= 1 and (allReady or totalPlayers == 1) then
        debugPrint("Game starting...")

        -- === COUNTDOWN PHASE ===
        transitionToState(GameState.COUNTDOWN)
        for i = COUNTDOWN_TIME, 1, -1 do
            debugPrint("Countdown: %d", i)
            GameCountdownEvent:FireAllClients(i, GameState.COUNTDOWN)
            task.wait(1)
        end

        -- === DRAWING PHASE ===
        transitionToState(GameState.DRAWING)
        playerDrawings = {} -- Clear previous drawings
        playerScores = {} -- Clear previous scores
        debugPrint("Cleared previous drawings and scores")

        -- TODO: Get the actual theme for the round
        local currentTheme = "Numbers" -- Placeholder

        for i = DRAWING_TIME, 0, -1 do
            GameCountdownEvent:FireAllClients(i, GameState.DRAWING)
            if i > 0 then task.wait(1) end -- Wait unless it's the last second
        end
        debugPrint("Drawing time complete.")
        task.wait(2) -- Short grace period for submissions

        -- === NEXT PHASE DECISION ===
        if currentGameMode == GameMode.SINGLE_PLAYER then
            -- === GRADING PHASE (Single Player) ===
            transitionToState(GameState.GRADING)
            debugPrint("Starting GRADING phase for single player.")

            local playersToGrade = #lobbyPlayers
            local playersGraded = 0
            -- Signal to wait for all grading tasks
            local allGradingCompleteSignal = Instance.new("BindableEvent")

            if playersToGrade == 0 then
                debugPrint("No players left to grade.")
                -- No need to wait, fire signal immediately
                allGradingCompleteSignal:Fire()
            else
                 -- Iterate and submit drawings for grading
                for _, p in ipairs(lobbyPlayers) do
                    local userId = p.UserId
                    local imageData = playerDrawings[userId]

                    if imageData then
                        -- Asynchronously grade each drawing
                        task.spawn(function()
                            local errorMessage = false -- Track success locally within spawn
                            local result = nil -- Track result locally
                            debugPrint("Submitting drawing for grading for player %s", p.Name)
                            result, errorMessage = BackendService:submitDrawingToBackendForGrading(p, imageData, currentTheme)
                            debugPrint("Result: %s", result)
                            debugPrint("ErrorMessage: %s", errorMessage)

                            if result and result.success then
                                debugPrint("Grading successful for %s", p.Name)
                                playerScores[userId] = { drawing = imageData, score = result.result.Score or "N/A", feedback = result.result.Feedback}
                            else
                                debugPrint("Grading failed for %s: %s", p.Name, errorMessage)
                                playerScores[userId] = { drawing = imageData, score = "Error", feedback = "Failed to grade drawing." }
                            end

                            -- Safely increment and check completion
                            playersGraded = playersGraded + 1
                            debugPrint("Players graded: %d/%d", playersGraded, playersToGrade)
                            if playersGraded == playersToGrade then
                                debugPrint("All players graded. Signaling completion.")
                                allGradingCompleteSignal:Fire() -- Signal completion
                            end
                        end)
                    else
                        -- This should never happen, but just in case
                        assert(false, "No drawing submitted for player %s, skipping grading.", p.Name)
                    end
                end
            end

            -- Wait here for all grading tasks to complete before proceeding
            if playersToGrade > 0 then
                debugPrint("Waiting for grading tasks to complete...")
                allGradingCompleteSignal.Event:Wait()
                debugPrint("Grading tasks complete.")
            end
            allGradingCompleteSignal:Destroy() -- Clean up the signal event

            -- Now that grading is finished, transition to RESULTS
            transitionToState(GameState.RESULTS)
            -- The RESULTS logic below will now execute correctly

        elseif currentGameMode == GameMode.MULTIPLAYER then
            -- === VOTING PHASE (Multiplayer) ===
            transitionToState(GameState.VOTING)
            debugPrint("Starting VOTING phase for multiplayer.")

            -- Prepare drawings for voting
            local drawingsForVoting = {}
            for userId, imageData in pairs(playerDrawings) do
                 -- Ensure the player who drew is still in the lobby
                local playerExists = false
                if not imageData then -- Add check for nil image data here too
                    debugPrint("Skipping drawing from player %s (no image data)", userId)
                    continue -- Skip to next iteration
                end
                for _, p in ipairs(lobbyPlayers) do
                    if p.UserId == userId then
                        playerExists = true
                        break
                    end
                end

                if playerExists then -- Only include drawings from players still present with data
                    table.insert(drawingsForVoting, {
                        playerId = userId,
                        imageData = imageData -- Consider sending compressed data if large
                    })
                else
                     debugPrint("Skipping drawing from player %s (not in lobby)", userId)
                end
            end

            -- Send drawings to all clients if there are any drawings
            if #drawingsForVoting > 0 then
                debugPrint("Sending %d drawings to clients for voting", #drawingsForVoting)
                for _, p in ipairs(lobbyPlayers) do
                    DrawingsReceivedEvent:FireClient(p, drawingsForVoting)
                end
            else
                debugPrint("No valid drawings available for voting.")
                -- If no drawings, skip voting? Or show a message?
                -- For now, proceed with timer, but no votes will be possible.
            end


            -- Reset voting variables
            playerVotes = {}
            voteResults = {}

            -- Start voting time countdown
            for i = VOTING_TIME, 0, -1 do
                GameCountdownEvent:FireAllClients(i, GameState.VOTING)
                 if i > 0 then task.wait(1) end
            end
            debugPrint("Voting time complete.")
            task.wait(2) -- Grace period for final votes

            -- Proceed to results after voting timer
            transitionToState(GameState.RESULTS)
            -- The RESULTS logic below will now execute correctly

        end
        
        local resultsData = nil

        -- === RESULTS PHASE ===
        -- This block now runs *after* either GRADING (and waiting) or VOTING completes and transitions here
        if currentState == GameState.RESULTS then -- Ensure we are in the correct state
            debugPrint("Entering RESULTS phase.")
            if currentGameMode == GameMode.SINGLE_PLAYER then
                debugPrint("Preparing single-player results.")
                resultsData = playerScores -- Send the scores collected during GRADING

            elseif currentGameMode == GameMode.MULTIPLAYER then
                debugPrint("Tallying multiplayer votes.")
                -- Tally votes (moved here from previous location)
                local winningPlayerId = nil
                local highestVotes = 0

                for votedId, count in pairs(voteResults) do
                    -- Ensure the voted player is still in the lobby
                    local playerExists = false
                    local votedPlayer = Players:GetPlayerByUserId(tonumber(votedId) or 0) -- More direct check
                    if votedPlayer then
                        for _, p in ipairs(lobbyPlayers) do
                            if p == votedPlayer then
                                playerExists = true
                                break
                            end
                        end
                    end


                    if playerExists then
                        debugPrint("Player %s received %d votes", votedId, count)
                        if count > highestVotes then
                            highestVotes = count
                            winningPlayerId = votedId
                        elseif count == highestVotes then
                             winningPlayerId = nil -- Handle ties by having no single winner for now
                             debugPrint("Tie detected at %d votes", highestVotes)
                        end
                    else
                        debugPrint("Ignoring votes for player %s (no longer in lobby)", votedId)
                    end
                end

                resultsData.votes = voteResults
                resultsData.winner = winningPlayerId

                if winningPlayerId then
                    local winnerName = Players:GetNameFromUserIdAsync(tonumber(winningPlayerId) or 0) or "Unknown"
                    debugPrint("Winner is %s (%s) with %d votes", winnerName, winningPlayerId, highestVotes)
                elseif #voteResults > 0 then
                     debugPrint("No single winner determined (tie or no votes for present players).")
                else
                    debugPrint("No votes were cast or tallied.")
                end
            end

            -- Send results to all clients
            -- debugPrint("Sending results to clients.")
            -- ShowResultsEvent:FireAllClients(resultsData)
            ShowResultsEvent:FireAllClients({Action = "Data", Data = resultsData})
            ShowResultsEvent:FireAllClients({Action = "Show"})
            wait(10)
            ShowResultsEvent:FireAllClients({Action = "Hide"})
            wait(1)

            -- === RETURN TO LOBBY ===
            debugPrint("Returning to LOBBY.")
            transitionToState(GameState.LOBBY)
            -- Ready status reset and lobby update happens within transitionToState(LOBBY)

        end -- End of RESULTS phase logic

    else
        debugPrint("Start game conditions not met (Ready: %d/%d, AllReady: %s)", readyCount, totalPlayers, tostring(allReady))
        -- Optionally send a message back to the host
    end
end)

-- Handle drawing submissions
SubmitDrawingEvent.OnServerEvent:Connect(function(player, imageData)
    if currentState == GameState.DRAWING or currentState == GameState.COUNTDOWN then
        -- Ensure we have valid image data
        if not imageData then
            warn("Received nil imageData from player: " .. player.Name)
            return -- Don't store or process nil data
        end

        -- Store the player's original drawing in memory
        -- Note: We store the original, uncompressed data here as requested.
        -- Compression happens in the analysis function.
        playerDrawings[player.UserId] = imageData
        debugPrint("Stored drawing from player: %s", player.Name)
    else
        debugPrint("Ignoring drawing from %s - received outside of drawing phase (current state: %s)",
            player.Name, currentState)
    end
end)

-- Handle votes (Only allow in Multiplayer Voting state)
SubmitVoteEvent.OnServerEvent:Connect(function(player, votedPlayerId)
    if currentState ~= GameState.VOTING or currentGameMode ~= GameMode.MULTIPLAYER then
        debugPrint("Ignoring vote from %s - incorrect state (%s) or mode (%s)", player.Name, currentState, currentGameMode)
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

function processExistingPlayers() 
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
end

processExistingPlayers()