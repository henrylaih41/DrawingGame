local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
local LeaderBoardBuilder = require(ReplicatedStorage.Modules.Utils.LeaderBoardBuilder)
local GameConfig = require(ReplicatedStorage.Modules.GameData.GameConfig)
local TopPlaysCanvas = require(ReplicatedStorage.Modules.Utils.TopPlaysCanvas)
local MainMenuScreen = PlayerGui:WaitForChild("MainMenuScreen")
local MainMenuButtons = MainMenuScreen:WaitForChild("TopLevelContainer"):WaitForChild("Buttons")
local GalleryButton = MainMenuButtons:WaitForChild("GalleryButton")
-- Get references to UI elements
local RankingScreen = PlayerGui:WaitForChild("RankingScreen")
local TopPlaysScreen = PlayerGui:WaitForChild("TopPlaysScreen")
local TopLevelContainer = RankingScreen:WaitForChild("TopLevelContainer")
local rowTemplate = ReplicatedStorage:WaitForChild("UI"):WaitForChild("PlayerRankRow")


local MAX_ROWS = GameConfig.RANKING_LIMIT
local ROWS_PER_PAGE = GameConfig.ROWS_PER_PAGE

-- Set up events
local Events = ReplicatedStorage:WaitForChild("Events")
local LocalPlayer = game:GetService("Players").LocalPlayer
local CanvasControllerFunction = LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("CanvasControllerFunction")
local cachedTopPlays = {}
local topPlaysContainers = {}
local scrollFrame = nil

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

local function displayTopPlays(topPlays)
    for i = 1, #topPlaysContainers do
        if i <= #topPlays then
            local drawingData = topPlays[i]
            TopPlaysCanvas.updateDrawingDisplayForRank(drawingData, i, topPlaysContainers)
        else
            TopPlaysCanvas.closeDrawingDisplayForRank(i, topPlaysContainers)
        end
    end
end

local function openTopPlays(userId)

    if (userId == nil) then
        warn("openTopPlays:userId is nil")
        return
    end

    if cachedTopPlays[tostring(userId)] then
        displayTopPlays(cachedTopPlays[tostring(userId)])
    else
        Events.RequestTopPlays:FireServer(userId)
    end
    TopPlaysScreen.Enabled = true
    TopPlaysScreen:FindFirstChild("TopLevelContainer").Visible = true
    CanvasControllerFunction:Invoke("StopRendering")
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
                        openTopPlays(score.value.uid)
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

local function initTopPlaysUI()
    local topLevelContainer = TopPlaysScreen:FindFirstChild("TopLevelContainer")
    -- Set to invisible first before we setup the canvas
    topLevelContainer.Visible = false
    scrollFrame = TopPlaysCanvas.setupTopPlaysCanvas(
        topLevelContainer, topPlaysContainers, 
        function()
            CanvasControllerFunction:Invoke("ResumeRendering")
            topLevelContainer.Visible = false
            TopPlaysScreen.Enabled = false

            if topPlaysContainers then
                for i, containerData in ipairs(topPlaysContainers) do
                    local container = containerData.container
                    local canvas = containerData.canvas
                    canvas:Clear()
                    local Loading = container:FindFirstChild("CanvasFrame"):FindFirstChild("Loading")
                    Loading.Visible = true
                end
            end
        end
    )

    Events.ReceiveTopPlays.OnClientEvent:Connect(function(topPlaysUserId, topPlays)
        if topPlays == nil then
            warn("Top plays are nil for player " .. topPlaysUserId)
            return
        end
        
        cachedTopPlays[tostring(topPlaysUserId)] = topPlays
        displayTopPlays(topPlays)
    end)

    -- Best scores button is just self rank view.
    GalleryButton.MouseButton1Click:Connect(function ()
        openTopPlays(LocalPlayer.UserId)
    end)

    -- After setup, disable the screen
    TopPlaysScreen.Enabled = false
end

initTopPlaysUI()
initRankingUI()