-- GameManager.server.lua
-- Manages the overall game flow and states

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local GameConfig = require(ReplicatedStorage.Modules.GameData.GameConfig)
local GameConstants = require(ReplicatedStorage.Modules.GameData.GameConstants)
local HttpService = game:GetService("HttpService")
local PlayerStore = require(ServerScriptService.modules.PlayerStore)
local TopPlaysStore = require(ServerScriptService.modules.TopPlaysStore)
local PlayerBestDrawingsStore = require(ServerScriptService.modules.PlayerBestDrawingsStore)
local TopDrawingCacheService = require(ServerScriptService.modules.TopDrawingCacheService)

-- Modules
local CanvasDraw = require(ReplicatedStorage.Modules.Canvas.CanvasDraw)
local BackendService = require(ServerScriptService.modules.BackendService)
local ThemeStore = require(ServerScriptService.modules.ThemeStore)
local ServerStates = require(ServerScriptService.modules.ServerStates)

-- Remote events
local Events = ReplicatedStorage:WaitForChild("Events")

local DEBUG_ENABLED = true

-- Get the player data, if it is not in memory, get it from the datastore.
local function getPlayerData(player)
    local playerData = ServerStates.PlayerState[player].playerData
    local errorMessage = nil
    
    if not playerData then
        playerData, errorMessage = PlayerStore:getPlayer(player)
        if not playerData then
            error("Failed to get player data for " .. player.Name .. ": " .. tostring(errorMessage))
        end
    end

    return playerData
end

local function savePlayerData(player, playerData)
    if playerData then
        local playerState = ServerStates.PlayerState[player]
        -- Update the cache
        playerState.playerData = playerData
        -- Notify the client
        Events.PlayerDataUpdated:FireClient(player, playerData)
    end
end

local function flushPlayerData(player: Player)
    local playerData = ServerStates.PlayerState[player].playerData
    if playerData then
        PlayerStore:savePlayer(player, playerData)
    end
end

-- Utility Functions
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

local function UpdatePlayerStateAndNotifyClient(player: Player, newState: string, additionalData)
    local playerState = ServerStates.PlayerState[player]
    debugPrint("Transitioning from %s to %s", playerState.state, newState)
    playerState.state = newState

    if newState == GameConstants.PlayerStateEnum.THEME_LIST then
        -- This is the canvas that the player is currently on.
        playerState.canvas = additionalData.canvas
    end
    
    local stateData = additionalData or {}
    stateData.state = newState
    
    Events.GameStateChanged:FireClient(player, stateData)
end

-- Player Management
local function handlePlayerJoined(player)
    warn(player.UserId)
    -- Update the player state.
    ServerStates.PlayerState[player] = {
        ownedCanvas = {},
        maximumOwnedCanvas = 1,
        state = GameConstants.PlayerStateEnum.IDLE,
        playerDrawings = nil,
        playerScores = nil,
        waitSignal = Instance.new("BindableEvent"),
    }

    -- Load the persistent player data.
    local playerData = getPlayerData(player)

    ServerStates.PlayerState[player].playerData = playerData

    -- Tell the new player the current game state
    Events.GameStateChanged:FireClient(player, {
        state = GameConstants.PlayerStateEnum.IDLE
    })

    -- Tell the new player the current player data
    Events.PlayerDataUpdated:FireClient(player, playerData)

    -- TODO: This is just for testing purpose. In prod, we should use drawings in player's gallery.
    task.spawn(function()
        task.wait(3)
        local topPlays = TopDrawingCacheService.fetch(1523877105)
        for i, c in ipairs(workspace:WaitForChild(GameConstants.DrawingCanvasFolderName):GetChildren()) do
            local topPlay = topPlays[i % (#topPlays - 1)]
            if (topPlay == nil) then
                continue
            end
            local theme = topPlay.theme
            local imageData = CanvasDraw.DecompressImageDataCustom(topPlay.imageData)
            Events.DrawToCanvas:FireAllClients(imageData, theme, c)
        end
    end)
end

local function handlePlayerLeft(player: Player)
    -- flush player data before removing
    flushPlayerData(player)
    
    -- Remove player from active players list
    ServerStates.PlayerState[player] = nil
end

local function runDrawingPhase(player: Player, currentTheme: string)
    local playerState = ServerStates.PlayerState[player]
    playerState.playerDrawings = nil
    playerState.playerScores = nil
    -- Wait for the player to submit.
    playerState.waitSignal.Event:Wait()
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

local function selfHealPlayer(player: Player)
    local playerData = getPlayerData(player)
    if not playerData.topPlaysWithoutImage or (#playerData.topPlaysWithoutImage < GameConfig.GALLERY_SLOTS) then
        local topPlays = TopPlaysStore:getTopPlays(tostring(player.UserId))
        local topPlaysWithoutImage = topPlaysWithoutImageFromTopPlays(topPlays)

        playerData.topPlaysWithoutImage = topPlaysWithoutImage
        savePlayerData(player, playerData)
    end
end 

local function sendTopPlaysToClient(player: Player, topPlaysUserId: string, topPlays)
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

    -- Decompress the image data and send it to the client.
    for i, playerBestDrawing in ipairs(topPlays) do
        local imageData = CanvasDraw.DecompressImageDataCustom(playerBestDrawing.imageData)
        local drawingData = {
            imageData = imageData,
            score = playerBestDrawing.score,
            feedback = playerBestDrawing.feedback,
            theme = playerBestDrawing.theme,
            theme_difficulty = playerBestDrawing.theme_difficulty,
            uuid = playerBestDrawing.uuid
        }
        bestDrawings[i] = drawingData
    end

    -- Send the data back to the requesting client
    Events.ReceiveTopPlays:FireClient(player, topPlaysUserId, bestDrawings)
end

-- imageData is a compressed image data returned by CompressImageDataCustom.
local function storeHighestScoringDrawing(player:Player, theme, imageData, score: number, feedback: string)
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
            playerId = player.UserId,
            uuid = HttpService:GenerateGUID(false)
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
            local topPlays = TopPlaysStore:getTopPlays(tostring(player.UserId))

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
            TopPlaysStore:saveTopPlays(tostring(player.UserId), topPlays)
            -- Send the new top plays to the client.
            sendTopPlaysToClient(player, tostring(player.UserId), topPlays)
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

local function runGradingPhase(player: Player, currentTheme: string)
    local playerState = ServerStates.PlayerState[player]
    local userId = player.UserId
    local imageData = playerState.playerDrawings
    if imageData then
        -- Asynchronously grade each drawing
        task.spawn(function()
            local result = nil
            local errorMessage = nil
            debugPrint("Submitting drawing for grading for player %s", player.Name)

            local playerData = getPlayerData(player)
            playerData.TotalPlayCount = playerData.TotalPlayCount + 1
            savePlayerData(player, playerData)

            local compressedImageData = nil
            result, errorMessage, compressedImageData = BackendService:submitDrawingToBackendForGrading(player, imageData, currentTheme)

            if result and result.success then
                debugPrint("Grading successful for %s", player.Name)
                playerState.playerScores = { 
                    drawing = imageData, 
                    score = result.result.Score, 
                    feedback = result.result.Feedback
                }
                
                local scoreValue = tonumber(result.result.Score) or 5
                -- TODO, we can optimizer here by returning the best drawing image data.
                -- This way we can avoid the getPlayerBestDrawing call later.
                -- We need to be careful since this function is called using a task spawn.
                -- We either have to make this blocking or use some synchronization mechanism.
                storeHighestScoringDrawing(player, currentTheme, compressedImageData, scoreValue, result.result.Feedback)

                -- TODO, once the grading is done, we check if the image is appropriate to be displayed.
                Events.DrawToCanvas:FireAllClients(imageData, currentTheme, playerState.canvas)
            else
                warn("Grading failed")
                playerState.playerScores[userId] = { 
                    drawing = imageData, 
                    score = 5, 
                    feedback = "Opps! Something went wrong. Sorry about that. Please try again later." 
                }
            end

            playerState.waitSignal:Fire()
        end)
    else
        warn("No drawing submitted for player %s, skipping grading.", player.Name)
    end

    playerState.waitSignal.Event:Wait()
end

-- Game Flow
local function startGame(player: Player, theme_uuid: string)
    local playerState = ServerStates.PlayerState[player]
    local currentTheme = ThemeStore:getTheme(theme_uuid)

    -- === DRAWING PHASE ===
    UpdatePlayerStateAndNotifyClient(player, GameConstants.PlayerStateEnum.DRAWING, {theme = currentTheme})
    runDrawingPhase(player, currentTheme)
    
        -- === GRADING PHASE (Single Player) ===
    UpdatePlayerStateAndNotifyClient(player, GameConstants.PlayerStateEnum.GRADING)
    runGradingPhase(player, currentTheme)

    -- Get the current best score for the theme
    local bestScoreData, errorMessage = PlayerBestDrawingsStore:getPlayerBestDrawing(player, currentTheme.uuid)
    local bestScore = nil   

    if not bestScoreData then
        if errorMessage then
            warn("Error getting best score for theme %s: %s", currentTheme, errorMessage)
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
    UpdatePlayerStateAndNotifyClient(player, GameConstants.PlayerStateEnum.RESULTS, 
        {bestScore = bestScore, playerScores = ServerStates.PlayerState[player].playerScores, theme = currentTheme})
    debugPrint("Displaying single-player results. Waiting for player to click menu button.")
    
    local connection
    
    -- Listen for ReturnToMainMenu event
    connection = Events.ReturnToMainMenu.OnServerEvent:Connect(function(player)
        playerState.waitSignal:Fire()
    end)

    playerState.waitSignal.Event:Wait()
    
    -- Clean up connection
    if connection then
        connection:Disconnect()
    end
    
    UpdatePlayerStateAndNotifyClient(player, GameConstants.PlayerStateEnum.IDLE)
end

local function handleDrawingSubmission(player, imageData)
    local playerState = ServerStates.PlayerState[player]
    -- Ensure we have valid image data
    if not imageData then
        warn("Received nil imageData from player: " .. player.Name)
        return
    end

    playerState.playerDrawings = imageData
    playerState.waitSignal:Fire()
end

local function handleStartGame(player: Player, theme_uuid: string)
    -- Start the game
    startGame(player, theme_uuid)
end

local function sendThemeListPageToClient(player)
    -- fetch all theme at once for now.
    local themeList = ThemeStore:getThemeSummary()
    Events.ReceiveThemeListPage:FireClient(player, themeList)
end

local function handleSendFeedback(player, feedback)
    BackendService:SendFeedbackRequest(player.Name, player.UserId, feedback)
end

local function handleClientStateChange(player, newState, additionalData)
    UpdatePlayerStateAndNotifyClient(player, newState, additionalData)
end

local function handleDeleteGalleryDrawing(player, uuid)
    local topPlays = TopDrawingCacheService.fetch(tostring(player.UserId))
    local deleted = false
    for i, topPlay in ipairs(topPlays) do
        if topPlay.uuid == uuid then
            table.remove(topPlays, i)
            deleted = true
            break
        end
    end

    if not deleted then
        warn("Failed to delete drawing with uuid: " .. uuid)
    end

    -- Save the updated top plays
    TopPlaysStore:saveTopPlays(tostring(player.UserId), topPlays)
    -- Purge the server cache
    TopDrawingCacheService.purgeCache(tostring(player.UserId))

    -- Send the updated top plays to the client.
    sendTopPlaysToClient(player, tostring(player.UserId), topPlays)
end

-- ServerScriptService/CanvasSurface.lua
local function attachSurfaceGui(canvasModel : Model,
                                pixelsPerStud : number,
                                maxPixels     : number,
                                face          : Enum.NormalId?)

    ----------------------------------------------------------------
    -- 0. Validate inputs
    ----------------------------------------------------------------
    local board = canvasModel.PrimaryPart
    if not board then
        error(("attachSurfaceGui: %q has no PrimaryPart"):format(canvasModel:GetFullName()))
    end

    if board:FindFirstChild("CanvasGui") then
        return board.CanvasGui                      -- already attached
    end

    pixelsPerStud = pixelsPerStud or 50
    maxPixels     = maxPixels     or 2048
    face          = face          or Enum.NormalId.Front   -- default

    ----------------------------------------------------------------
    -- 1. Build the SurfaceGui
    ----------------------------------------------------------------
    local gui               = Instance.new("SurfaceGui")
    gui.Name                = "CanvasGui"
    gui.ResetOnSpawn        = false
    gui.LightInfluence      = 0
    gui.ZIndexBehavior      = Enum.ZIndexBehavior.Global
    gui.SizingMode          = Enum.SurfaceGuiSizingMode.PixelsPerStud
    gui.PixelsPerStud       = pixelsPerStud
    gui.Face                = face
    gui.ClipsDescendants    = true
    gui.Adornee             = board
    gui.Parent              = board     -- replication happens here

    ----------------------------------------------------------------
    -- 2. Compute the board’s width / height *on that face*
    ----------------------------------------------------------------
    local size = board.Size
    local widthStuds, heightStuds

    if face == Enum.NormalId.Front or face == Enum.NormalId.Back then
        widthStuds, heightStuds = size.X, size.Y          -- X-by-Y
    elseif face == Enum.NormalId.Left or face == Enum.NormalId.Right then
        widthStuds, heightStuds = size.Z, size.Y          -- Z-by-Y
    else -- Top / Bottom
        widthStuds, heightStuds = size.X, size.Z          -- X-by-Z
    end

    local pxW = math.clamp(math.floor(widthStuds  * pixelsPerStud), 32, maxPixels)
    local pxH = math.clamp(math.floor(heightStuds * pixelsPerStud), 32, maxPixels)
    gui.CanvasSize = Vector2.new(pxW, pxH)

    ----------------------------------------------------------------
    -- 3. Add an ImageLabel that fills the surface
    ----------------------------------------------------------------
    local img             = Instance.new("ImageLabel")
    img.Name              = "DrawingImage"
    img.BackgroundTransparency = 1
    img.BorderSizePixel   = 0
    img.Size              = UDim2.fromScale(1, 1)
    img.ScaleType         = Enum.ScaleType.Fit        -- keeps aspect
    img.Parent            = gui

    -- Only add an aspect-ratio constraint if the board isn’t square
    if math.abs(widthStuds - heightStuds) > 0.01 then
        local ar          = Instance.new("UIAspectRatioConstraint")
        ar.AspectRatio    = widthStuds / heightStuds
        ar.Parent         = img
    end

    return gui
end

-- Initialize
local function init()

    -- Player might already be in the game
    for _, p in ipairs(Players:GetPlayers()) do
        task.spawn(handlePlayerJoined, p)
    end

    -- Initialize the canvas state for all canvas in the workspace.
    for _, c in ipairs(workspace:WaitForChild(GameConstants.DrawingCanvasFolderName):GetChildren()) do
        ServerStates.CanvasState[c] = {
            registered = false,
            ownerPlayer = nil
        }

        local faceAttr = c:GetAttribute("CanvasFace")
        if faceAttr then
            local faceEnum = Enum.NormalId[faceAttr] 
            attachSurfaceGui(c, 50, 2048, faceEnum)
        else
            attachSurfaceGui(c, 50, 2048)
        end
    end

    -- Connect event handlers
    Players.PlayerAdded:Connect(handlePlayerJoined)
    Players.PlayerRemoving:Connect(handlePlayerLeft)
    Events.StartGame.OnServerEvent:Connect(handleStartGame)
    Events.SubmitDrawing.OnServerEvent:Connect(handleDrawingSubmission)
    Events.RequestTopPlays.OnServerEvent:Connect(sendTopPlaysToClient)
    Events.RequestThemeListPage.OnServerEvent:Connect(sendThemeListPageToClient)
    Events.SendFeedback.OnServerEvent:Connect(handleSendFeedback)
    Events.ClientStateChange.OnServerEvent:Connect(handleClientStateChange)
    Events.DeleteGalleryDrawing.OnServerEvent:Connect(handleDeleteGalleryDrawing)
    Events.TestEvent.OnServerEvent:Connect(function(player)
    end)
end

-- Start the module
init()


-- local ThemeLoader = require(ServerScriptService.modules.ThemeLoader)
-- ThemeLoader:loadThemes()
