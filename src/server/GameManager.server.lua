-- GameManager.server.lua
-- Manages the overall game flow and states

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local GameConfig = require(ReplicatedStorage.Modules.GameData.GameConfig)
local PlayerStore = require(ServerScriptService.modules.PlayerStore)
local TopPlaysStore = require(ServerScriptService.modules.TopPlaysStore)
local PlayerBestDrawingsStore = require(ServerScriptService.modules.PlayerBestDrawingsStore)
local TopDrawingCacheService = require(ServerScriptService.modules.TopDrawingCacheService)

-- Modules
local CanvasDraw = require(ReplicatedStorage.Modules.Canvas.CanvasDraw)
local BackendService = require(ServerScriptService.modules.BackendService)
local ThemeStore = require(ServerScriptService.modules.ThemeStore)

-- Constants
local CONSTANTS = {
    MAX_PLAYERS = 1,
    COUNTDOWN_TIME = 1,
    VOTING_TIME = 30, -- 30 seconds for voting
    DEBUG_ENABLED = true
}

-- Game state definitions
local GameState = {
    MAIN_MENU = "MAIN_MENU",
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
local Events = ReplicatedStorage:WaitForChild("Events")

-- Game state tracking
local GameManager = {
    currentState = GameState.MAIN_MENU,
    currentGameMode = GameMode.SINGLE_PLAYER,
    activePlayers = {},
    playerDrawings = {},
    playerVotes = {},
    voteResults = {},
    playerScores = {},
    playerData = {} -- Table to store player data
}

local function getPlayerData(player)
    local playerData = GameManager.playerData[player.UserId]
    local errorMessage = nil
    if not playerData then
        playerData, errorMessage = PlayerStore:getPlayer(player)
        assert(playerData, "Failed to get player data for " .. player.Name .. ": " .. tostring(errorMessage))
    end
    GameManager.playerData[player.UserId] = playerData
    return playerData
end

local function savePlayerData(player, playerData, flush)
    local flush = flush or true
    if playerData then
        -- Update the cache
        GameManager.playerData[player.UserId] = playerData
        if flush then
            -- Save to datastore
            PlayerStore:savePlayer(player, playerData)
        end
        -- Notify the client
        Events.PlayerDataUpdated:FireClient(player, playerData)
    end
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
    
    for _, player in ipairs(GameManager.activePlayers) do
        Events.GameStateChanged:FireClient(player, stateData)
    end
end

local function transitionToState(newState, additionalData)
    debugPrint("Transitioning from %s to %s", GameManager.currentState, newState)
    GameManager.currentState = newState
    
    local stateData = additionalData or {}
    stateData.state = newState
    stateData.gameMode = GameManager.currentGameMode
    
    broadcastGameState(stateData)
end

-- Player Management
local function handlePlayerJoined(player)
    table.insert(GameManager.activePlayers, player)

    local playerData = getPlayerData(player)
    
    -- Tell the new player the current game state
    debugPrint("Sending current game state to new player: %s", GameManager.currentState)
    Events.GameStateChanged:FireClient(player, {
        state = GameManager.currentState,
        gameMode = GameManager.currentGameMode
    })

    Events.PlayerDataUpdated:FireClient(player, playerData)
end

local function handlePlayerLeft(player)
    -- Save player data before removing
    savePlayerData(player)
    
    -- Remove player from active players list
    for i, p in ipairs(GameManager.activePlayers) do
        if p == player then
            table.remove(GameManager.activePlayers, i)
            break
        end
    end
    
    -- Clear player data from memory
    if GameManager.playerData[player.UserId] then
        GameManager.playerData[player.UserId] = nil
    end
    
    -- Clear player drawings if needed
    if GameManager.playerDrawings[player.UserId] then
        GameManager.playerDrawings[player.UserId] = nil
    end
    
    -- If no players remain, reset the game
    if #GameManager.activePlayers == 0 then
        GameManager.currentState = GameState.MAIN_MENU
        GameManager.playerDrawings = {}
        GameManager.playerScores = {}
        GameManager.voteResults = {}
        GameManager.skipDrawingTime = false
        -- Don't clear playerData here as we've already saved and cleared individual entries
    end
end

local function runDrawingPhase(currentTheme)
    GameManager.playerDrawings = {} -- Clear previous drawings
    GameManager.playerScores = {} -- Clear previous scores
    GameManager.skipDrawingTime = false -- Reset skip flag
    debugPrint("Cleared previous drawings and scores")

    local drawingTime = currentTheme.Duration * 60

    for i = drawingTime, 0, -1 do
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

local function topPlaysWithoutImageFromTopPlays(topPlays)
    local topPlaysWithoutImage = {}

    -- Get the stripped down top plays
    for i, topPlay in ipairs(topPlays) do
        local topPlayWithoutImage = {
            theme = topPlay.theme,
            score = topPlay.score,
            points = topPlay.points,
            timestamp = topPlay.timestamp,
            theme_uuid = topPlay.theme_uuid,
            theme_difficulty = topPlay.theme_difficulty,
            playerId = topPlay.playerId,
            imageData = nil
        }

        table.insert(topPlaysWithoutImage, topPlayWithoutImage)
    end

    return topPlaysWithoutImage
end

local function selfHealPlayer(player)
    local playerData = getPlayerData(player)
    if not playerData.topPlaysWithoutImage or (#playerData.topPlaysWithoutImage < GameConfig.TOP_PLAYS_LIMIT) then
        local topPlays = TopPlaysStore:getTopPlays(player.UserId)
        local topPlaysWithoutImage = topPlaysWithoutImageFromTopPlays(topPlays)

        playerData.topPlaysWithoutImage = topPlaysWithoutImage
        savePlayerData(player, playerData)
    end
end 

local function sendTopPlaysToClient(player, topPlaysUserId, topPlays)
    debugPrint("Player %s requested top plays of %s", player.Name, topPlaysUserId)

    -- If no topPlays are provided, get them from the backend.
    if not topPlays then
        topPlays = TopDrawingCacheService.fetch(topPlaysUserId)
        if topPlays == nil then
            warn("Failed to fetch top plays for player " .. topPlaysUserId)
            return
        end
    end

    table.sort(topPlays, function(a, b)
        return a.points > b.points
    end)

    -- Create a table to store the best drawing data for each theme
    local bestDrawings = {}
    local playerPoints = 0
    -- For each theme, get the player's best drawing
    for i, playerBestDrawing in ipairs(topPlays) do
        local imageData = CanvasDraw.DecompressImageDataCustom(playerBestDrawing.imageData)
        playerPoints = playerPoints + playerBestDrawing.points

        local drawingData = {
            imageData = imageData,
            score = playerBestDrawing.score,
            feedback = playerBestDrawing.feedback,
            theme = playerBestDrawing.theme,
            theme_difficulty = playerBestDrawing.theme_difficulty
        }
        bestDrawings[i] = drawingData
    end

    -- Only self heal TotalPoints if the topPlays are for the local player.
    if tostring(player.UserId) == tostring(topPlaysUserId) then
        local playerData = getPlayerData(player)

        if(playerPoints ~= playerData.TotalPoints) then
            warn("Player points do not match")
            if playerPoints then 
                warn("Player points: " .. playerPoints)
            end
            if playerData.TotalPoints then
                warn("Player points: " .. playerData.TotalPoints)
            end
            -- Self Healing
            playerData.TotalPoints = playerPoints
            PlayerStore:savePlayer(player, playerData)
            Events.PlayerDataUpdated:FireClient(player, playerData)
        end
    end
    
    -- Send the data back to the requesting client
    Events.ReceiveTopPlays:FireClient(player, topPlaysUserId, bestDrawings)
end

-- imageData is a compressed image data returned by CompressImageDataCustom.
local function storeHighestScoringDrawing(player, theme, imageData, score, feedback)
    -- Check if there's an existing drawing for this theme
    local existingData, errorMessage = PlayerBestDrawingsStore:getPlayerBestDrawing(player, theme.uuid)
    local existingScore = 0
    local shouldSaveDrawing = false
    
    if not existingData or errorMessage then
        -- No existing drawing found, save this one
        debugPrint("No existing drawing found for theme '%s'. Saving new drawing.", theme)
        shouldSaveDrawing = true
    else
        -- Compare scores to see if we should update
        existingScore = tonumber(existingData.score) or 0
        if score > existingScore then
            debugPrint("New drawing score (%d) is higher than existing score (%d) for theme '%s'. Updating.", 
                score, existingScore, theme)
            shouldSaveDrawing = true
        else
            debugPrint("Existing drawing has higher or equal score (%d vs %d) for theme '%s'. Keeping existing drawing.", 
                existingScore, score, theme)
        end
    end
    
    -- Save the drawing if needed
    if shouldSaveDrawing then
        local drawingData = {
            imageData = imageData,
            points = score,
            score = score,
            timestamp = os.time(),
            theme = theme.Name,
            theme_difficulty = theme.Difficulty,
            theme_uuid = theme.uuid,
            playerId = player.UserId
        }

        local success, error = PlayerBestDrawingsStore:savePlayerBestDrawing(player, theme.uuid, drawingData)
        if not success then
            warn("Failed to save player best drawing for theme '%s': %s", theme, error)
        end
        
        -- self healing - topPlaysWithoutImage
        selfHealPlayer(player)
        -- At this point, the playerData must contain the topPlaysWithoutImage field.
        local playerData = getPlayerData(player)

        local shouldAddToTopPlays, replaceThemeUuid 
            = TopPlaysStore:checkIfNewBestDrawingChangesTopPlays(playerData.topPlaysWithoutImage, drawingData)

        if shouldAddToTopPlays then
            -- Get the real topPlays with ImageData
            local topPlays = TopPlaysStore:getTopPlays(player.UserId)

            if replaceThemeUuid then
                -- Replace the old top play with the new one
                for i, topPlay in ipairs(topPlays) do
                    if topPlay.theme_uuid == replaceThemeUuid then
                        topPlays[i] = drawingData
                    end
                end
            -- If replaceThemeUuid is nil, it means we should just insert the new drawing.
            else
                table.insert(topPlays, drawingData)
            end

            -- Do the update, we update the topPlaysWithoutImage and the topPlays.
            local topPlaysWithoutImage = topPlaysWithoutImageFromTopPlays(topPlays)
            playerData.topPlaysWithoutImage = topPlaysWithoutImage

            local totalPoints = 0
            for _, topPlay in ipairs(topPlays) do
                totalPoints = totalPoints + topPlay.points
                playerData.TotalPoints = totalPoints
            end

            savePlayerData(player, playerData)
            TopPlaysStore:saveTopPlays(player, topPlays)
            -- Send the new top plays to the client.
            sendTopPlaysToClient(player, player.UserId, topPlays)
        end

        local rawImageData = CanvasDraw.DecompressImageDataCustom(imageData)
        -- Notify the client that a new best drawing for this theme has been saved
        Events.ReceiveNewBestDrawing:FireClient(player, {imageData = rawImageData, score = score, feedback = feedback}, theme)
        if success then
            debugPrint("Successfully saved drawing for theme '%s'", theme)
        else
            debugPrint("Failed to save drawing for theme '%s': %s", theme, error)
        end
    end
end

local function runGradingPhase(currentTheme)
    local playersToGrade = #GameManager.activePlayers
    local playersGraded = 0
    local allGradingCompleteSignal = Instance.new("BindableEvent")

    -- Iterate and submit drawings for grading
    for _, p in ipairs(GameManager.activePlayers) do
        local userId = p.UserId
        local imageData = GameManager.playerDrawings[userId]

        if imageData then
            -- Asynchronously grade each drawing
            task.spawn(function()
                local errorMessage = false
                local result = nil
                debugPrint("Submitting drawing for grading for player %s", p.Name)

                local playerData = getPlayerData(p)
                playerData.TotalPlayCount = playerData.TotalPlayCount + 1
                savePlayerData(p, playerData, false)

                local compressedImageData = nil
                result, errorMessage, compressedImageData = BackendService:submitDrawingToBackendForGrading(p, imageData, currentTheme)

                if result and result.success then
                    debugPrint("Grading successful for %s", p.Name)
                    GameManager.playerScores[userId] = { 
                        drawing = imageData, 
                        score = result.result.Score or "5", 
                        feedback = result.result.Feedback
                    }
                    
                    -- Store best drawing for this theme in datastore
                    task.spawn(function()
                        local scoreValue = tonumber(result.result.Score) or 5
                        -- TODO, we can optimizer here by returning the best drawing image data.
                        -- This way we can avoid the getPlayerBestDrawing call later.
                        -- We need to be careful since this function is called using a task spawn.
                        -- We either have to make this blocking or use some synchronization mechanism.
                        storeHighestScoringDrawing(p, currentTheme, compressedImageData, scoreValue, result.result.Feedback)
                    end)
                else
                    debugPrint("Grading failed for %s: %s", p.Name, errorMessage)
                    GameManager.playerScores[userId] = { 
                        drawing = imageData, 
                        score = 5, 
                        feedback = "Opps! Something went wrong. Sorry about that. Please try again later." 
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

-- Game Flow
local function startGame(theme_uuid)
    -- Reset game state
    GameManager.playerDrawings = {}
    GameManager.playerScores = {}
    GameManager.voteResults = {}
    GameManager.skipDrawingTime = false
    
    local currentTheme = ThemeStore:getTheme(theme_uuid)

    -- === DRAWING PHASE ===
    transitionToState(GameState.DRAWING, {theme = currentTheme})
    runDrawingPhase(currentTheme)
    
    -- === NEXT PHASE BASED ON GAME MODE ===
    if GameManager.currentGameMode == GameMode.SINGLE_PLAYER then
        -- === GRADING PHASE (Single Player) ===
        transitionToState(GameState.GRADING)
        debugPrint("Starting GRADING phase for single player.")
        runGradingPhase(currentTheme)
        debugPrint("Getting best score for theme %s", currentTheme)
        local player = GameManager.activePlayers[1]
        assert(player, "No player found in active players")

        -- Get the current best score for the theme
        local bestScoreData, errorMessage = PlayerBestDrawingsStore:getPlayerBestDrawing(player, currentTheme.uuid)
        local bestScore = nil   

        -- If there is no best score, this means that the player has not submitted a drawing yet.
        if not bestScoreData then
            if errorMessage then
                -- warn("Error getting best score for theme %s: %s", currentTheme, errorMessage)
            end
            bestScore = {
                drawing = nil,
                score = 0,
                feedback = "No drawing found"
            }
        else 
            local imageData = CanvasDraw.DecompressImageDataCustom(bestScoreData.imageData)
            bestScore = {
                drawing = imageData,
                score = bestScoreData.score,
                feedback = bestScoreData.feedback
            }
        end

        -- === RESULTS PHASE ===
        transitionToState(GameState.RESULTS, {bestScore = bestScore, playerScores = GameManager.playerScores, theme = currentTheme})
        debugPrint("Displaying single-player results. Waiting for player to click menu button.")
        
        -- Create variables to track when to continue
        local returnToMenuRequested = false
        local connection
        
        -- Listen for ReturnToMainMenu event
        connection = Events.ReturnToMainMenu.OnServerEvent:Connect(function(player)
            if table.find(GameManager.activePlayers, player) then
                debugPrint("Player %s clicked to return to main menu", player.Name)
                returnToMenuRequested = true
            end
        end)
        
        while not returnToMenuRequested do
            task.wait(0.5) -- Check every half second to avoid busy waiting
        end
        
        -- Clean up connection
        if connection then
            connection:Disconnect()
        end
    end
    
    -- === RETURN TO MAIN MENU ===
    debugPrint("Returning to main menu.")
    transitionToState(GameState.MAIN_MENU)
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
        for _, p in ipairs(GameManager.activePlayers) do
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

-- Handle start game request from client
local function handleStartGame(player, theme_uuid)
    if GameManager.currentState ~= GameState.MAIN_MENU then
        debugPrint("Ignoring start game request - game already in progress")
        return
    end
    
    debugPrint("Starting game requested by %s for theme: %s", player.Name, theme_uuid)
    
    GameManager.currentGameMode = GameMode.SINGLE_PLAYER
    
    -- Ensure requesting player is in active players
    local playerInGame = false
    for _, p in ipairs(GameManager.activePlayers) do
        if p == player then
            playerInGame = true
            break
        end
    end
    
    if not playerInGame then
        table.insert(GameManager.activePlayers, player)
    end
    
    -- Start the game
    startGame(theme_uuid)
end

local function sendThemeListPageToClient(player)
    -- fetch all theme at once for now.
    local themeList = ThemeStore:getThemeSummary(GameConfig.THEME_LIST_LIMIT)
    Events.ReceiveThemeListPage:FireClient(player, themeList)
end

-- Initialize
local function init()

    -- Player might already be in the game
    for _, p in ipairs(Players:GetPlayers()) do
        task.spawn(handlePlayerJoined, p)
    end

    -- Connect event handlers
    Players.PlayerAdded:Connect(handlePlayerJoined)
    Players.PlayerRemoving:Connect(handlePlayerLeft)
    Events.StartGame.OnServerEvent:Connect(handleStartGame)
    Events.SubmitDrawing.OnServerEvent:Connect(handleDrawingSubmission)
    Events.SubmitVote.OnServerEvent:Connect(handleVoteSubmission)
    Events.RequestTopPlays.OnServerEvent:Connect(sendTopPlaysToClient)
    Events.RequestThemeListPage.OnServerEvent:Connect(sendThemeListPageToClient)

    Events.TestEvent.OnServerEvent:Connect(function(player)
        local userId = player.UserId
        print("Test event received: " .. userId)
        local topDrawings = TopDrawingCacheService.fetch(userId)
        print(topDrawings)
    end)

    
    debugPrint("GameManager initialized")
end

-- Start the module
init()

-- local ThemeLoader = require(ServerScriptService.modules.ThemeLoader)
-- ThemeLoader:loadThemes()
