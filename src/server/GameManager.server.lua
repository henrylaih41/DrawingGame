-- GameManager.server.lua
-- Manages the overall game flow and states

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")
local GameConstants = require(ReplicatedStorage.Modules.GameData.GameConstants)
local PlayerStore = require(ServerScriptService.modules.PlayerStore)
local TopPlaysStore = require(ServerScriptService.modules.TopPlaysStore)
local PlayerBestDrawingsStore = require(ServerScriptService.modules.PlayerBestDrawingsStore)
local TopPlaysCacheService = require(ServerScriptService.modules.TopPlaysCacheService)
local LeaderboardService = require(ServerScriptService.modules.LeaderboardService)

-- Modules
local CanvasDraw = require(ReplicatedStorage.Modules.Canvas.CanvasDraw)
local DisplayCanvasSelector = require(ServerScriptService.modules.DisplayCanvasSelector)
local BackendService = require(ServerScriptService.modules.BackendService)
local ThemeStore = require(ServerScriptService.modules.ThemeStore)
local ServerStates = require(ServerScriptService.modules.ServerStates)
local CanvasManager = require(ServerScriptService.modules.CanvasManager)

-- Remote events
local Events = ReplicatedStorage:WaitForChild("Events")

local ServerConfig = require(ServerScriptService.modules.ServerConfig)
local DEBUG_ENABLED = ServerConfig.DEBUG_ENABLED

local function getDifficultyMultiplier(difficulty: string)
    if difficulty == "Easy" then
        return 1
    elseif difficulty == "Medium" then
        return 2
    elseif difficulty == "Hard" then
        return 3
    else
        warn("Unknown difficulty: " .. difficulty)
        return 1
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

local function sendLoginMessage(player: Player, playerData: PlayerStore.PlayerData)
    local pointsGained = playerData.TotalPoints - playerData.PreviousTotalPoints
    local message = nil
    local delayTime = 8
    if pointsGained > 0 then
        message = "Welcome back! Your drawing gained " .. pointsGained .. " likes while you were away!"
    else
        message = "Welcome to Drawing Theme League!"
        delayTime = 3
    end
    Events.ShowNotification:FireClient(player, message, "green", delayTime)
end

-- Selects random drawings from the top players to populate display canvases.
local function populateDisplayCanvases()
    local topScores = LeaderboardService.getCachedTopScores()
    if not topScores or #topScores == 0 then
        warn("No top scores available to populate display canvases")
        return
    end

    local usedDrawingIds = {}

    for _, canvas in pairs(CollectionService:GetTagged("DisplayCanvas")) do
        local drawing = DisplayCanvasSelector.selectRandomDrawing(
            topScores,
            TopPlaysCacheService.fetch,
            usedDrawingIds,
            ServerConfig.DISPLAY_CANVAS.MAX_RANDOM_ATTEMPTS
        )

        if canvas == nil then
            warn("Canvas is nil in populateDisplayCanvases")
            return
        end

        if drawing then
            ServerStates.CanvasState[canvas].drawing = drawing
        else
            ServerStates.CanvasState[canvas].drawing = nil
        end
    end

    -- Signal that the display canvas drawings are ready
    ServerStates.ServerDisplayImageReady = true
end

-- Player Management
local function handlePlayerJoined(player)
    -- Update the player state.
    ServerStates.PlayerState[player] = {
        ownedCanvas = {},
        maximumOwnedCanvas = ServerConfig.DEFAULT_MAXIMUM_OWNED_CANVAS,
        state = GameConstants.PlayerStateEnum.IDLE,
        playerDrawings = nil,
        playerScores = nil,
        waitSignal = Instance.new("BindableEvent"),
    }

    ServerStates.PlayerIdToPlayerMap[tostring(player.UserId)] = player

    -- Load the persistent player data.
    local playerData = PlayerStore:getPlayer(tostring(player.UserId), player.Name)

    sendLoginMessage(player, playerData)

    -- Tell the new player the current game state
    Events.GameStateChanged:FireClient(player, {
        state = GameConstants.PlayerStateEnum.IDLE
    })

    -- Tell the new player the current player data
    Events.PlayerDataUpdated:FireClient(player, playerData)

    -- Send cached display canvas drawings to the newly joined player.
end

local function handlePlayerLeft(player: Player)
    local playerData = PlayerStore:getPlayer(tostring(player.UserId))
    local ownedCanvasList = ServerStates.PlayerState[player].ownedCanvas
    local canvasTTL = playerData.drawingTTLAfterPlayerLeft

    -- Spawn a task that removes the player's canvas after the TTL.
    for _, canvas in ipairs(ownedCanvasList) do
        task.spawn(function()
            -- Only let the drawing live if there is drawing data.
            if (ServerStates.CanvasState[canvas].drawing) then
                task.wait(canvasTTL)
            end 
            CanvasManager.resetCanvas(canvas)
        end)
    end

    -- Remove player from active players list
    ServerStates.PlayerState[player] = nil
    ServerStates.PlayerIdToPlayerMap[tostring(player.UserId)] = nil

    -- Save the previous total points.
    playerData.PreviousTotalPoints = playerData.TotalPoints
    PlayerStore:savePlayer(tostring(player.UserId), playerData)
end

local function runDrawingPhase(player: Player, currentTheme: string)
    local playerState = ServerStates.PlayerState[player]
    playerState.playerDrawings = nil
    playerState.playerScores = nil
    -- Wait for the player to submit.
    playerState.waitSignal.Event:Wait()
    return currentTheme
end

local function sendTopPlaysToClient(player: Player, topPlaysUserId: string, topPlays)
    debugPrint("Player %s requested top plays of %s", player.Name, topPlaysUserId)

    -- If no topPlays are provided, get them from the backend.
    if not topPlays then
        topPlays = TopPlaysCacheService.fetch(topPlaysUserId)
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

local function storeHighestScoringDrawing(player:Player, drawingData: PlayerBestDrawingsStore.DrawingData)
    -- Check if there's an existing drawing for this theme
    local theme_uuid = drawingData.theme_uuid
    local existingData, errorMessage = PlayerBestDrawingsStore:getPlayerBestDrawing(player, theme_uuid)
    local existingScore = 0
    local shouldSaveDrawing = false
    
    if not existingData or errorMessage then
        -- No existing drawing found, save this one
        debugPrint("No existing drawing found for theme '%s'. Saving new drawing.", drawingData.theme)
        shouldSaveDrawing = true
    else
        -- Compare scores to see if we should update
        existingScore = tonumber(existingData.score) or 0
        if drawingData.score > existingScore then
            shouldSaveDrawing = true
        end
    end

    local playerData = PlayerStore:getPlayer(tostring(player.UserId))
    playerData.TotalPoints = playerData.TotalPoints + drawingData.points
    PlayerStore:savePlayer(tostring(player.UserId), playerData)
    Events.PlayerDataUpdated:FireClient(player, playerData)
    Events.ShowNotification:FireClient(player, "You earned " .. drawingData.points .. " points!", "green")
    
    -- Save the drawing if needed
    if shouldSaveDrawing then
        
        local success, error = PlayerBestDrawingsStore:savePlayerBestDrawing(player, theme_uuid, drawingData)

        if not success then
            warn("Failed to save player best drawing for theme '%s': %s", theme_uuid, error)
        end

        local rawImageData = CanvasDraw.DecompressImageDataCustom(drawingData.imageData)
        -- Notify the client that a new best drawing for this theme has been saved
        Events.ReceiveNewBestDrawing:FireClient(player, {imageData = rawImageData, score = drawingData.score})
    end
end

local function runGradingPhase(player: Player, currentTheme: ThemeStore.Theme)
    local playerState = ServerStates.PlayerState[player]
    local imageData = playerState.playerDrawings
    if imageData then
        -- Asynchronously grade each drawing
        task.spawn(function()
            local result = nil
            local errorMessage = nil
            debugPrint("Submitting drawing for grading for player %s", player.Name)

            local playerData = PlayerStore:getPlayer(tostring(player.UserId))
            playerData.TotalPlayCount = playerData.TotalPlayCount + 1
            PlayerStore:savePlayer(tostring(player.UserId), playerData, false)

            local compressedImageData = nil
            result, errorMessage, compressedImageData = BackendService:submitDrawingToBackendForGrading(player, imageData, currentTheme)

            if result and result.success then
                local score = tonumber(result.result.Score) or 5
                local points = score * getDifficultyMultiplier(currentTheme.Difficulty)
                local drawingData = PlayerBestDrawingsStore:createDrawingData(
                    compressedImageData, score, points, currentTheme, tostring(player.UserId))

                playerState.drawingData = drawingData

                playerState.playerScores = {
                    drawing = imageData,
                    score = drawingData.score,
                    feedback = result.result.Feedback,
                    theme = currentTheme
                } 
                
                storeHighestScoringDrawing(player, drawingData)

                if playerState.canvas == nil then
                    warn("Canvas is nil in runGradingPhase")
                    return
                end
                
                -- TODO, once the grading is done, we check if the image is appropriate to be displayed.

                -- Save the player drawing data to the canvas state so we can display it to other players
                -- that join the game later.
                ServerStates.CanvasState[playerState.canvas].drawing = {
                        imageData = imageData,
                        themeName = drawingData.themeName,
                        playerId = drawingData.playerId,
                        drawingId = drawingData.uuid,
                }

            -- If the canvas is registered, we request the drawing data from the server.
                Events.DrawToCanvas:FireAllClients(imageData, 
                    {themeName = drawingData.themeName, canvas = playerState.canvas, 
                     playerId = drawingData.playerId, drawingId = drawingData.uuid})
            else
                warn("Grading failed")
                playerState.playerScores = { 
                    drawing = imageData, 
                    score = 5, 
                    feedback = "Opps! Something went wrong. Sorry about that. Please try again later.",
                    theme = currentTheme
                }
            end

            playerState.waitSignal:Fire()
        end)
    else
        warn("No drawing submitted for player %s, skipping grading.", player.Name)
    end

    playerState.waitSignal.Event:Wait()
end

-- TopPlays equals the gallery.
local function handleSaveToGallery(player: Player, imageData: string)
    local topPlays = TopPlaysCacheService.fetch(tostring(player.UserId))
    local playerData = PlayerStore:getPlayer(tostring(player.UserId))
    local playerState = ServerStates.PlayerState[player]

    if #topPlays >= playerData.maximumGallerySize then
        Events.ShowNotification:FireClient(player, 
            "Gallery is full. Please delete some drawings to make space.",
            "red"
        )
    else
        table.insert(topPlays, playerState.drawingData)
        -- Save the new top plays.
        local success, _ = TopPlaysStore:saveTopPlays(tostring(player.UserId), topPlays)
        if not success then
            warn("Failed to save top plays for player " .. player.UserId)
            Events.ShowNotification:FireClient(player, 
                "Failed to save drawing to gallery. Please try again later.",
                "red"
            )
            return
        end
        TopPlaysCacheService.purgeCache(tostring(player.UserId))
        Events.ShowNotification:FireClient(player, 
            "Successfully saved drawing to gallery."
        )
        -- Send the new top plays to the client.
        sendTopPlaysToClient(player, tostring(player.UserId), topPlays)
    end
end

-- Game Flow
local function startDrawing(player: Player, theme_uuid: string)
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

local function handlestartDrawing(player: Player, theme_uuid: string)
    -- Check if the player has enough energy to draw.
    local playerData = PlayerStore:getPlayer(tostring(player.UserId))

    if playerData.Energy <= 0 then
        Events.ShowNotification:FireClient(player, "You don't have enough energy to draw.", "red")
        return
    else
        -- Consume one energy.
        playerData.Energy = playerData.Energy - 1
        PlayerStore:savePlayer(tostring(player.UserId), playerData)
    end
    
    -- Start the game
    startDrawing(player, theme_uuid)
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
    local topPlays = TopPlaysCacheService.fetch(tostring(player.UserId))
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
    TopPlaysCacheService.purgeCache(tostring(player.UserId))

    -- Send the updated top plays to the client.
    sendTopPlaysToClient(player, tostring(player.UserId), topPlays)
end

local function handleDisplayCanvasDrawingRequest(player: Player, canvas: Instance)
    -- Add timeout mechanism
    local maxWaitTime = ServerConfig.DISPLAY_CANVAS.MAX_WAIT_TIME -- Maximum wait time in seconds
    local startTime = os.time()
    
    while ServerStates.ServerDisplayImageReady == false do
        -- Check if we've exceeded the timeout
        if os.time() - startTime >= maxWaitTime then
            warn("Timed out waiting for ServerDisplayImageReady to be true")
            return
        end
        task.wait(1)
    end

    -- Check if we have drawing data for this canvas
    local drawing = ServerStates.CanvasState[canvas].drawing

    if drawing then
        Events.DrawToCanvas:FireClient(player, drawing.imageData,
            {themeName = drawing.themeName, canvas = canvas, playerId = drawing.playerId, drawingId = drawing.drawingId})
    else
        Events.DrawToCanvas:FireClient(player, nil, {canvas = canvas})
    end
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
    -- 2. Compute the board's width / height *on that face*
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

    -- Only add an aspect-ratio constraint if the board isn't square
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

    for _, c in pairs(CollectionService:GetTagged("Canvas")) do
        ServerStates.CanvasState[c] = {
            registered = false,
            ownerPlayer = nil,
            drawing = nil
        }

        local faceAttr = c:GetAttribute("CanvasFace")
        if faceAttr then
            local faceEnum = Enum.NormalId[faceAttr] 
            attachSurfaceGui(c, 50, 2048, faceEnum)

        else
            attachSurfaceGui(c, 50, 2048)
        end
    end

    -- Populate the display canvases once using top player drawings.
    task.spawn(populateDisplayCanvases)

    -- Connect event handlers
    Players.PlayerAdded:Connect(handlePlayerJoined)
    Players.PlayerRemoving:Connect(handlePlayerLeft)
    Events.startDrawing.OnServerEvent:Connect(handlestartDrawing)
    Events.SubmitDrawing.OnServerEvent:Connect(handleDrawingSubmission)
    Events.RequestTopPlays.OnServerEvent:Connect(sendTopPlaysToClient)
    Events.RequestThemeListPage.OnServerEvent:Connect(sendThemeListPageToClient)
    Events.SendFeedback.OnServerEvent:Connect(handleSendFeedback)
    Events.ClientStateChange.OnServerEvent:Connect(handleClientStateChange)
    Events.DeleteGalleryDrawing.OnServerEvent:Connect(handleDeleteGalleryDrawing)
    Events.SaveToGallery.OnServerEvent:Connect(handleSaveToGallery)
    Events.TestEvent.OnServerEvent:Connect(function(player)
    end)
    Events.RequestDisplayCanvasDrawing.OnServerEvent:Connect(handleDisplayCanvasDrawingRequest)
end

-- Start the module
init()


-- local ThemeLoader = require(ServerScriptService.modules.ThemeLoader)
-- ThemeLoader:loadThemes()
