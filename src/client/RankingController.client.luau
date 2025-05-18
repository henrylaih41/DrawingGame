local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
local LeaderBoardBuilder = require(ReplicatedStorage.Modules.Utils.LeaderBoardBuilder)
local GameConfig = require(ReplicatedStorage.Modules.GameData.GameConfig)
local GalleryCanvas = require(ReplicatedStorage.Modules.Utils.GalleryCanvas)
local CommonHelper = require(ReplicatedStorage.Modules.Utils.CommonHelper)
local NotificationService = require(ReplicatedStorage.Modules.Utils.NotificationService)
local MainMenuScreen = PlayerGui:WaitForChild("MainMenuScreen")
local MainMenuButtons = MainMenuScreen:WaitForChild("TopLevelContainer"):WaitForChild("Buttons")
local GalleryButton = MainMenuButtons:WaitForChild("GalleryButton")
-- Get references to UI elements
local RankingScreen = PlayerGui:WaitForChild("RankingScreen")
local GalleryScreen = PlayerGui:WaitForChild("GalleryScreen")
local TopLevelContainer = RankingScreen:WaitForChild("TopLevelContainer")
local rowTemplate = ReplicatedStorage:WaitForChild("UI"):WaitForChild("PlayerRankRow")


local MAX_ROWS = GameConfig.RANKING_LIMIT
local ROWS_PER_PAGE = GameConfig.ROWS_PER_PAGE

-- Set up events
local Events = ReplicatedStorage:WaitForChild("Events")
local LocalPlayer = game:GetService("Players").LocalPlayer
local CanvasControllerFunction = LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("CanvasControllerFunction")
local galleryInitialized = false
local cachedTopPlays = {}
local galleryContainers = {}

local function createRow(name)
    local row = rowTemplate:Clone()
    local YOffset = TopLevelContainer.AbsoluteSize.Y * rowTemplate.Size.Y.Scale
    row.Size = UDim2.new(1, 0, 0, YOffset)
    row.Name = name
    row.RankLabel.Text = ""
    row.NameLabel.Text = ""
    row.ScoreLabel.Text = ""
    return row
end

local function updateLabel(pageLbl, currentPage, pageCount)
    pageLbl.Text = string.format("%d / %d", currentPage, pageCount)
end

local function openTopPlays(userId: string, topPlays)
    if (topPlays == nil) then
        warn("openTopPlays:userId is nil")
        return
    end

    if (#topPlays > #galleryContainers) then
        warn("Top plays are greater than the number of gallery containers " .. #topPlays .. " > " .. #galleryContainers)
    end

    -- Clean and Hide all the containers to start from a clean state.
    for i = 1, #galleryContainers do
        local container = galleryContainers[i]
        container.containerFrame.Visible = false
        -- Only show the delete button for the local player gallery.
        if userId == tostring(LocalPlayer.UserId) then
            container.containerFrame:WaitForChild("DeleteButton").Visible = true
        else 
            container.containerFrame:WaitForChild("DeleteButton").Visible = false
        end

        GalleryCanvas.deleteDrawing(container)
    end

    for i = 1, math.min(#topPlays, #galleryContainers) do
        local drawingData = topPlays[i]
        local container = galleryContainers[i]
        -- Update the container with the new drawing data
        GalleryCanvas.updateDrawingDisplayForRank(drawingData, container)
        container.containerFrame.Visible = true
    end

    GalleryScreen.Enabled = true
    GalleryScreen:FindFirstChild("TopLevelContainer").Visible = true
    CanvasControllerFunction:Invoke("StopRendering")
end

local function displayPlayerGallery(playerUserId: string)
    -- check cache first
    -- NOTE
    -- We don't cache the player's own gallery, since we might update it.
    -- We can revisit this in the future if there is performance issues.
    if playerUserId ~= tostring(LocalPlayer.UserId) and cachedTopPlays[playerUserId] then
        openTopPlays(playerUserId, cachedTopPlays[playerUserId])
    else
        -- request from server
        Events.RequestTopPlays:FireServer(playerUserId)
    end
end

local function initRankingUI()
    local row_per_page = ROWS_PER_PAGE
    local pageCount = math.ceil(MAX_ROWS / row_per_page)
    local prevBtn, nextBtn, closeBtn, pageLbl, pageLayout 
        = LeaderBoardBuilder.Create(TopLevelContainer, MAX_ROWS, createRow, createRow,row_per_page)

    local currentPage = 1
    updateLabel(pageLbl, currentPage, pageCount)

    closeBtn.MouseButton1Click:Connect(function()
        TopLevelContainer.Visible = false
    end)

    prevBtn.MouseButton1Click:Connect(function()
        if currentPage > 1 then
            currentPage -= 1
            pageLayout:JumpToIndex(currentPage - 1)
            updateLabel(pageLbl, currentPage, pageCount)
        end
    end)

    nextBtn.MouseButton1Click:Connect(function()
        if currentPage < pageCount then
            currentPage += 1
            pageLayout:JumpToIndex(currentPage - 1)
            updateLabel(pageLbl, currentPage, pageCount)
        end
    end)

    local pageContainer = TopLevelContainer:FindFirstChild("PageContainer")
    local header = TopLevelContainer:FindFirstChild("Header")
    header.NameLabel.Text = "Name"
    header.RankLabel.Text = "Rank"
    header.ScoreLabel.Text = "Score"
    Events.ReceiveTopScores.OnClientEvent:Connect(function(topScores, playerData)
        local pageFrame = nil 
        local rank = "..."
        for i, score in ipairs(topScores) do
            local uuid = score.key
            local page_index = math.ceil(i / row_per_page)
            local row_index = i - (page_index - 1) * row_per_page
            pageFrame = pageContainer:FindFirstChild("Page_" .. page_index)
            if pageFrame then
                local row = pageFrame:FindFirstChild("Row" .. row_index)
                if row then
                    -- Mark the player's row with a different color
                    if uuid == tostring(LocalPlayer.UserId) then
                        row.BackgroundColor3 = GameConfig.SELECTED_COLOR
                        rank = i
                    end
                    row.RankLabel.Text = i
                    row.NameLabel.Text = score.value.name
                    row.ScoreLabel.Text = score.value.points
                    row.ViewButton.Visible = true
                    row.ViewButton.MouseButton1Click:Connect(function() 
                        displayPlayerGallery(score.value.uid)
                    end)
                end
            end
        end
        local playerRank = TopLevelContainer:FindFirstChild("Footer")
        if playerRank then
            playerRank.BackgroundColor3 = GameConfig.SELECTED_COLOR
            playerRank.RankLabel.Text = rank
            playerRank.NameLabel.Text = playerData.Name
            playerRank.ScoreLabel.Text = playerData.TotalPoints
        end
    end)

    Events.RequestTopScores:FireServer()
end

local function initGalleryUI(gallerySlots: number)
    local topLevelContainer = GalleryScreen:FindFirstChild("TopLevelContainer")
    GalleryScreen.Enabled = true
    -- Set to invisible first before we setup the canvas
    topLevelContainer.Visible = false
    GalleryCanvas.setupGalleryCanvas(
        topLevelContainer, galleryContainers, gallerySlots,
        function()
            CanvasControllerFunction:Invoke("ResumeRendering")
            topLevelContainer.Visible = false
            GalleryScreen.Enabled = false

            if galleryContainers then
                for i, containerData in ipairs(galleryContainers) do
                    local containerFrame = containerData.containerFrame
                    local editableImage = containerData.editableImage
                    CommonHelper.destroyEditableImage(editableImage)
                    containerData.editableImage = nil
                    local Loading = containerFrame:FindFirstChild("CanvasFrame"):FindFirstChild("Loading")
                    Loading.Visible = true
                end
            end
        end,
        function(containerFrame)
            NotificationService:ShowConfirmationBox("Are you sure you want to delete this drawing?")
            local confirmed = NotificationService:GetConfirmation()
            if confirmed then
                local uuid = containerFrame:GetAttribute("drawing_uuid")
                Events.DeleteGalleryDrawing:FireServer(uuid)
            end
        end
    )

    -- After setup, disable the screen
    GalleryScreen.Enabled = false
end

initRankingUI()

-- Init the button. The gallery is initalized after the player clicks the button.
GalleryButton.MouseButton1Click:Connect(function ()
    displayPlayerGallery(tostring(LocalPlayer.UserId))
end)

Events.ReceiveTopPlays.OnClientEvent:Connect(function(topPlaysUserId: string, topPlays)
    if topPlays == nil then
        warn("Top plays are nil for player " .. topPlaysUserId)
        return
    end
    
    if not galleryInitialized then
        -- The maximum number of gallery slots is set in the GameConfig.
        initGalleryUI(GameConfig.GALLERY_SLOTS)
        galleryInitialized = true
    end

    cachedTopPlays[topPlaysUserId] = topPlays
    openTopPlays(topPlaysUserId, topPlays)
end)

