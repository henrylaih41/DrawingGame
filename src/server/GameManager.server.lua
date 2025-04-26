-- GameManager.server.lua
-- Manages the overall game flow and states

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local CanvasDraw = require(ReplicatedStorage.Modules.Canvas.CanvasDraw)
local BackendService = require(ReplicatedStorage.Modules.Services.BackendService)
local ThemeList = require(ReplicatedStorage.Modules.GameData.ThemeList)

-- Constants
local CONSTANTS = {
    MAX_PLAYERS = 8,
    COUNTDOWN_TIME = 1,
    DRAWING_TIME = 500, -- 3 minutes
    VOTING_TIME = 30, -- 30 seconds for voting
    DEBUG_ENABLED = true
}

-- Game state definitions
local GameState = {
    LOBBY = "LOBBY",
    COUNTDOWN = "COUNTDOWN",
    DRAWING = "DRAWING",
    GRADING = "GRADING",
    VOTING = "VOTING",
    RESULTS = "RESULTS"
}

local GameMode = {
    SINGLE_PLAYER = "SINGLE_PLAYER",
    MULTIPLAYER = "MULTIPLAYER"
}

-- Remote events
local Events = {
    GameStateChanged = nil,
    UpdateLobbyPlayers = nil,
    PlayerReady = nil,
    StartGame = nil,
    GameCountdown = nil,
    SubmitDrawing = nil,
    DrawingsReceived = nil,
    SubmitVote = nil,
    ShowResults = nil
}

-- Game state tracking
local GameManager = {
    currentState = GameState.LOBBY,
    currentGameMode = GameMode.SINGLE_PLAYER,
    lobbyPlayers = {},
    hostPlayer = nil,
    readyPlayers = {},
    playerDrawings = {},
    playerVotes = {},
    voteResults = {},
    playerScores = {}
}

-- Initialize events
local function initializeEvents()
    local EventsFolder = ReplicatedStorage:WaitForChild("Events")
    
    -- Get all required events with WaitForChild
    Events.GameStateChanged = EventsFolder:WaitForChild("GameStateChanged")
    Events.UpdateLobbyPlayers = EventsFolder:WaitForChild("UpdateLobbyPlayers")
    Events.PlayerReady = EventsFolder:WaitForChild("PlayerReady")
    Events.StartGame = EventsFolder:WaitForChild("StartGame")
    Events.GameCountdown = EventsFolder:WaitForChild("GameCountdown")
    Events.SubmitDrawing = EventsFolder:WaitForChild("SubmitDrawing")
    Events.DrawingsReceived = EventsFolder:WaitForChild("DrawingsReceived")
    Events.SubmitVote = EventsFolder:WaitForChild("SubmitVote")
    Events.ShowResults = EventsFolder:WaitForChild("ShowResults")
end

-- Utility Functions
local function debugPrint(message, ...)
    if CONSTANTS.DEBUG_ENABLED then
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

-- Core Game State Management
local function broadcastGameState(stateData)
    -- If no stateData provided, use default current state
    if not stateData then
        stateData = {
            state = GameManager.currentState,
            gameMode = GameManager.currentGameMode,
            -- Additional default data can be added here
        }
    end
    
    for _, player in ipairs(GameManager.lobbyPlayers) do
        Events.GameStateChanged:FireClient(player, stateData)
    end
end

local function updateLobbyPlayers()
    Events.UpdateLobbyPlayers:FireAllClients(
        GameManager.lobbyPlayers, 
        GameManager.hostPlayer, 
        GameManager.readyPlayers
    )
end

local function transitionToState(newState, additionalData)
    debugPrint("Transitioning from %s to %s", GameManager.currentState, newState)
    GameManager.currentState = newState
    
    local stateData = additionalData or {}
    stateData.state = newState
    stateData.gameMode = GameManager.currentGameMode
    
    broadcastGameState(stateData)

    -- State-specific initialization
    if newState == GameState.LOBBY then
        -- Reset ready status when returning to lobby
        for userId, _ in pairs(GameManager.readyPlayers) do
            GameManager.readyPlayers[userId] = false
        end
        debugPrint("Reset all ready statuses for LOBBY")
        updateLobbyPlayers()
    end
end

-- Player Management
local function handlePlayerJoined(player)
    debugPrint("Player joined: %s", player.Name)
    -- If this is the first player, they become the host
    if #GameManager.lobbyPlayers == 0 then
        GameManager.hostPlayer = player
        debugPrint("Set host player to: %s", player.Name)
    end
    
    table.insert(GameManager.lobbyPlayers, player)
    GameManager.readyPlayers[player.UserId] = false
    
    -- Update all clients with the new player list
    updateLobbyPlayers()
    
    -- Tell the new player the current game state
    debugPrint("Sending current game state to new player: %s", GameManager.currentState)
    Events.GameStateChanged:FireClient(player, GameManager.currentState)
end

local function handlePlayerLeft(player)
    debugPrint("Player leaving: %s", player.Name)
    -- Remove player from the lobby list
    for i, p in ipairs(GameManager.lobbyPlayers) do
        if p == player then
            table.remove(GameManager.lobbyPlayers, i)
            debugPrint("Removed player from lobby list")
            break
        end
    end
    
    -- Clear ready status
    GameManager.readyPlayers[player.UserId] = nil
    debugPrint("Cleared ready status for player")
    
    -- If the host left, assign a new host
    if GameManager.hostPlayer == player and #GameManager.lobbyPlayers > 0 then
        GameManager.hostPlayer = GameManager.lobbyPlayers[1]
        debugPrint("Host left, new host is: %s", GameManager.hostPlayer.Name)
    end
    
    -- Update all clients
    updateLobbyPlayers()
end

local function processExistingPlayers() 
    debugPrint("Processing existing players when script starts")
    for _, player in ipairs(Players:GetPlayers()) do
        handlePlayerJoined(player)
    end
    debugPrint("Done processing existing players")
end

-- Game Phases
local function runCountdownPhase()
    for i = CONSTANTS.COUNTDOWN_TIME, 1, -1 do
        debugPrint("Countdown: %d", i)
        Events.GameCountdown:FireAllClients(i, GameState.COUNTDOWN)
        task.wait(1)
    end
end

local function runDrawingPhase(currentTheme)
    GameManager.playerDrawings = {} -- Clear previous drawings
    GameManager.playerScores = {} -- Clear previous scores
    GameManager.skipDrawingTime = false -- Reset skip flag
    debugPrint("Cleared previous drawings and scores")

    -- Theme is now passed as a parameter, no need to select it here

    for i = CONSTANTS.DRAWING_TIME, 0, -1 do
        -- Check if we should skip the remaining time
        if GameManager.skipDrawingTime then
            debugPrint("Skipping remaining drawing time as all players have submitted.")
            break
        end
        
        Events.GameCountdown:FireAllClients(i, GameState.DRAWING)
        if i > 0 then task.wait(1) end -- Wait unless it's the last second
    end

    debugPrint("Drawing phase complete.")
    if not GameManager.skipDrawingTime then
        task.wait(1) -- Short grace period for submissions
    end
    
    return currentTheme
end

local function runGradingPhase(currentTheme)
    local playersToGrade = #GameManager.lobbyPlayers
    local playersGraded = 0
    local allGradingCompleteSignal = Instance.new("BindableEvent")

    -- Iterate and submit drawings for grading
    for _, p in ipairs(GameManager.lobbyPlayers) do
        local userId = p.UserId
        local imageData = GameManager.playerDrawings[userId]

        if imageData then
            -- Asynchronously grade each drawing
            task.spawn(function()
                local errorMessage = false
                local result = nil
                debugPrint("Submitting drawing for grading for player %s", p.Name)
                result, errorMessage = BackendService:submitDrawingToBackendForGrading(p, imageData, currentTheme)

                if result and result.success then
                    debugPrint("Grading successful for %s", p.Name)
                    GameManager.playerScores[userId] = { 
                        drawing = imageData, 
                        score = result.result.Score or "5", 
                        feedback = result.result.Feedback
                    }
                else
                    debugPrint("Grading failed for %s: %s", p.Name, errorMessage)
                    GameManager.playerScores[userId] = { 
                        drawing = imageData, 
                        score = "Error", 
                        feedback = "Failed to grade drawing." 
                    }
                end

                playersGraded = playersGraded + 1
                debugPrint("Players graded: %d/%d", playersGraded, playersToGrade)
                if playersGraded == playersToGrade then
                    debugPrint("All players graded. Signaling completion.")
                    allGradingCompleteSignal:Fire()
                end
            end)
        else
            assert(false, "No drawing submitted for player %s, skipping grading.", p.Name)
        end
    end

    if playersToGrade > 0 then
        debugPrint("Waiting for grading tasks to complete...")
        allGradingCompleteSignal.Event:Wait()
        debugPrint("Grading tasks complete.")
    end
    allGradingCompleteSignal:Destroy()
end

local function runVotingPhase()
    -- Prepare drawings for voting
    local drawingsForVoting = {}
    for userId, imageData in pairs(GameManager.playerDrawings) do
        -- Ensure the player who drew is still in the lobby
        local playerExists = false
        if not imageData then
            debugPrint("Skipping drawing from player %s (no image data)", userId)
            continue
        end
        
        for _, p in ipairs(GameManager.lobbyPlayers) do
            if p.UserId == userId then
                playerExists = true
                break
            end
        end

        if playerExists then
            table.insert(drawingsForVoting, {
                playerId = userId,
                imageData = imageData
            })
        else
            debugPrint("Skipping drawing from player %s (not in lobby)", userId)
        end
    end

    -- Send drawings to all clients if there are any drawings
    if #drawingsForVoting > 0 then
        debugPrint("Sending %d drawings to clients for voting", #drawingsForVoting)
        for _, p in ipairs(GameManager.lobbyPlayers) do
            Events.DrawingsReceived:FireClient(p, drawingsForVoting)
        end
    else
        debugPrint("No valid drawings available for voting.")
    end

    -- Reset voting variables
    GameManager.playerVotes = {}
    GameManager.voteResults = {}

    -- Start voting time countdown
    for i = CONSTANTS.VOTING_TIME, 0, -1 do
        Events.GameCountdown:FireAllClients(i, GameState.VOTING)
        if i > 0 then task.wait(1) end
    end
    debugPrint("Voting time complete.")
    task.wait(2) -- Grace period for final votes
end

local function getMultiplayerResults()
    local resultsData = {}
    debugPrint("Tallying multiplayer votes.")
    
    -- Tally votes
    local winningPlayerId = nil
    local highestVotes = 0

    for votedId, count in pairs(GameManager.voteResults) do
        -- Ensure the voted player is still in the lobby
        local playerExists = false
        local votedPlayer = Players:GetPlayerByUserId(tonumber(votedId) or 0)
        
        if votedPlayer then
            for _, p in ipairs(GameManager.lobbyPlayers) do
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
                winningPlayerId = nil -- Handle ties
                debugPrint("Tie detected at %d votes", highestVotes)
            end
        else
            debugPrint("Ignoring votes for player %s (no longer in lobby)", votedId)
        end
    end

    resultsData.votes = GameManager.voteResults
    resultsData.winner = winningPlayerId

    if winningPlayerId then
        local winnerName = Players:GetNameFromUserIdAsync(tonumber(winningPlayerId) or 0) or "Unknown"
        debugPrint("Winner is %s (%s) with %d votes", winnerName, winningPlayerId, highestVotes)
    elseif next(GameManager.voteResults) ~= nil then
        debugPrint("No single winner determined (tie or no votes for present players).")
    else
        debugPrint("No votes were cast or tallied.")
    end
    
    return resultsData
end

-- Game Flow
local function startGame()
    -- === COUNTDOWN PHASE ===
    transitionToState(GameState.COUNTDOWN)
    runCountdownPhase()
    
    -- Select theme before starting drawing phase
    local themeIndex = math.random(1, #ThemeList)
    local currentTheme = ThemeList[themeIndex]
    debugPrint("Selected theme for this round: %s", currentTheme)
    
    -- === DRAWING PHASE ===
    transitionToState(GameState.DRAWING, {theme = currentTheme})
    runDrawingPhase(currentTheme)
    
    -- === NEXT PHASE BASED ON GAME MODE ===
    local resultsData = nil
    
    if GameManager.currentGameMode == GameMode.SINGLE_PLAYER then
        -- === GRADING PHASE (Single Player) ===
        transitionToState(GameState.GRADING)
        debugPrint("Starting GRADING phase for single player.")
        runGradingPhase(currentTheme)
        
        -- === RESULTS PHASE ===
        transitionToState(GameState.RESULTS, {playerScores = GameManager.playerScores, theme = currentTheme})
        debugPrint("Preparing single-player results.")
        task.wait(15)
        
    elseif GameManager.currentGameMode == GameMode.MULTIPLAYER then
        -- === VOTING PHASE (Multiplayer) ===
        transitionToState(GameState.VOTING)
        debugPrint("Starting VOTING phase for multiplayer.")
        runVotingPhase()
        
        -- === RESULTS PHASE ===
        transitionToState(GameState.RESULTS)
        resultsData = getMultiplayerResults()
    end
    
    -- === RETURN TO LOBBY ===
    debugPrint("Returning to LOBBY.")
    transitionToState(GameState.LOBBY)
end

-- Event Handlers
local function handleStartGameRequest(player)
    debugPrint("Received start game request from player: %s", player.Name)
    if player ~= GameManager.hostPlayer or GameManager.currentState ~= GameState.LOBBY then
        debugPrint("Start game request denied (not host or not in lobby)")
        return
    end

    -- Check readiness
    local allReady = true
    local readyCount = 0
    local totalPlayers = #GameManager.lobbyPlayers

    for p_userId, isReady in pairs(GameManager.readyPlayers) do
        -- Ensure the player is still in the lobby
        local playerInLobby = false
        for _, lobby_p in ipairs(GameManager.lobbyPlayers) do
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

    -- Start game if conditions met
    if readyCount >= 1 and (allReady or totalPlayers == 1) then
        debugPrint("Game starting...")
        startGame()
    else
        debugPrint("Start game conditions not met (Ready: %d/%d, AllReady: %s)", 
            readyCount, totalPlayers, tostring(allReady))
    end
end

local function handleReadyStatusChange(player, isReady)
    debugPrint("Player %s ready status changed to: %s", player.Name, tostring(isReady))
    if GameManager.readyPlayers[player.UserId] ~= nil then
        GameManager.readyPlayers[player.UserId] = isReady
        updateLobbyPlayers()
    end
end

local function handleDrawingSubmission(player, imageData)
    if GameManager.currentState == GameState.DRAWING then
        -- Ensure we have valid image data
        if not imageData then
            warn("Received nil imageData from player: " .. player.Name)
            return
        end

        GameManager.playerDrawings[player.UserId] = imageData
        debugPrint("Stored drawing from player: %s", player.Name)
        
        -- Check if all players have submitted drawings
        local allSubmitted = true
        for _, p in ipairs(GameManager.lobbyPlayers) do
            if not GameManager.playerDrawings[p.UserId] then
                allSubmitted = false
                break
            end
        end
        
        -- If all players have submitted, move to the next phase
        if allSubmitted then
            debugPrint("All players have submitted drawings. Advancing to next phase.")
            -- Signal to skip the remaining drawing time
            GameManager.skipDrawingTime = true
        end
    else
        debugPrint("Ignoring drawing from %s - received outside of drawing phase (current state: %s)",
            player.Name, GameManager.currentState)
    end
end

local function handleVoteSubmission(player, votedPlayerId)
    if GameManager.currentState ~= GameState.VOTING or GameManager.currentGameMode ~= GameMode.MULTIPLAYER then
        debugPrint("Ignoring vote from %s - incorrect state (%s) or mode (%s)", 
            player.Name, GameManager.currentState, GameManager.currentGameMode)
        return
    end

    -- Check if player has already voted
    if GameManager.playerVotes[player.UserId] then
        debugPrint("Player %s already voted", player.Name)
        return
    end
    
    -- Record the vote
    GameManager.playerVotes[player.UserId] = votedPlayerId
    
    -- Tally the vote
    local votedId = tostring(votedPlayerId)
    GameManager.voteResults[votedId] = (GameManager.voteResults[votedId] or 0) + 1
    
    debugPrint("Player %s voted for %s", player.Name, votedId)
end

-- Initialize
local function init()
    initializeEvents()
    
    -- Connect event handlers
    Players.PlayerAdded:Connect(handlePlayerJoined)
    Players.PlayerRemoving:Connect(handlePlayerLeft)
    Events.PlayerReady.OnServerEvent:Connect(handleReadyStatusChange)
    Events.StartGame.OnServerEvent:Connect(handleStartGameRequest)
    Events.SubmitDrawing.OnServerEvent:Connect(handleDrawingSubmission)
    Events.SubmitVote.OnServerEvent:Connect(handleVoteSubmission)
    
    -- Process any players already in game
    processExistingPlayers()
    
    debugPrint("GameManager initialized")
end

-- Start the module
init()