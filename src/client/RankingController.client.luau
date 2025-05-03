local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local LeaderBoardBuilder = require(ReplicatedStorage.Modules.Utils.LeaderBoardBuilder)

-- Get references to UI elements
local PlayerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
local SocialService = game:GetService("SocialService")
local RankingScreen = PlayerGui:WaitForChild("RankingScreen")
local TopLevelContainer = RankingScreen:WaitForChild("TopLevelContainer")
local rowTemplate = ReplicatedStorage:WaitForChild("UI"):WaitForChild("PlayerRankRow")

local MAX_ROWS = 100 -- TODO: Get from server.
local ROWS_PER_PAGE = 10

-- Set up events
local Events = ReplicatedStorage:WaitForChild("Events")
local RequestTopScoresEvent = Events:WaitForChild("RequestTopScores")
local ReceiveTopScoresEvent = Events:WaitForChild("ReceiveTopScores")
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

local function initRankingUI()
    local row_per_page = 20
    LeaderBoardBuilder.Create(TopLevelContainer, MAX_ROWS, createRow, row_per_page)
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
            pageFrame = pageContainer:FindFirstChild("Page_" .. page_index)
            if pageFrame then
                local row = pageFrame:FindFirstChild("Row" .. i)
                if row then
                    -- Mark the player's row with a different color
                    if uuid == tostring(LocalPlayer.UserId) then
                        row.BackgroundColor3 = Color3.fromRGB(128, 208, 255)
                        rank = i
                    end
                    row.RankLabel.Text = i
                    row.NameLabel.Text = score.value.name
                    row.ScoreLabel.Text = score.value.points
                end
            end
        end
        local playerRank = TopLevelContainer:FindFirstChild("PlayerRank")
        if playerRank then
            playerRank.BackgroundColor3 = Color3.fromRGB(128, 208, 255)
            playerRank.RankLabel.Text = rank
            playerRank.NameLabel.Text = playerData.Name
            playerRank.ScoreLabel.Text = playerData.TotalPoints
        end
    end)

    Events.RequestTopScores:FireServer()
end

initRankingUI()