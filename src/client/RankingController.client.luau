local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LeaderBoardBuilder = require(ReplicatedStorage.Modules.Utils.LeaderBoardBuilder)
local GameConfig = require(ReplicatedStorage.Modules.GameData.GameConfig)

-- Get references to UI elements
local PlayerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
local RankingScreen = PlayerGui:WaitForChild("RankingScreen")
local TopLevelContainer = RankingScreen:WaitForChild("TopLevelContainer")
local rowTemplate = ReplicatedStorage:WaitForChild("UI"):WaitForChild("PlayerRankRow")

local MAX_ROWS = GameConfig.RANKING_LIMIT
local ROWS_PER_PAGE = GameConfig.ROWS_PER_PAGE

-- Set up events
local Events = ReplicatedStorage:WaitForChild("Events")
local LocalPlayer = game:GetService("Players").LocalPlayer

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
local function initRankingUI()
    local row_per_page = ROWS_PER_PAGE
    local pageCount = math.ceil(MAX_ROWS / row_per_page)
    local prevBtn, nextBtn, pageLbl, pageLayout 
        = LeaderBoardBuilder.Create(TopLevelContainer, MAX_ROWS, createRow, createRow,row_per_page)

    local currentPage = 1
    updateLabel(pageLbl, currentPage, pageCount)

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

initRankingUI()