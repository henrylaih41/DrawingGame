local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")

-- Get references to UI elements
local PlayerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
local RankingScreen = PlayerGui:WaitForChild("RankingScreen")
local TopLevelContainer = RankingScreen:WaitForChild("TopLevelContainer")
local Rows = TopLevelContainer:WaitForChild("Rows")
local TopBar = TopLevelContainer:WaitForChild("TopBar")
local CloseButton = TopBar:WaitForChild("CloseButton")

local MAX_ROWS = 100 -- TODO: Get from server.
-- Set up events
local Events = ReplicatedStorage:WaitForChild("Events")
local RequestTopScoresEvent = Events:WaitForChild("RequestTopScores")
local ReceiveTopScoresEvent = Events:WaitForChild("ReceiveTopScores")

local function initRankingUI()
    Rows.ScrollBarThickness = 12
    Rows.ScrollingDirection = Enum.ScrollingDirection.Y
    Rows.Active = true                           -- capture drags/touch

    CloseButton.MouseButton1Click:Connect(function()
        TopLevelContainer.Visible = false
    end)

    local rowTemplate = ReplicatedStorage:WaitForChild("UI"):WaitForChild("PlayerRankRow")
    for i = 1, 12 do
        local row = rowTemplate:Clone()
        local YOffset = TopLevelContainer.AbsoluteSize.Y * rowTemplate.Size.Y.Scale
        print(YOffset, rowTemplate.Size.Y.Scale)
        row.Size = UDim2.new(1, 0, 0, YOffset)
        row.Parent = Rows
        row.Name = "Row" .. i
        row.RankLabel.Text = ""
        row.NameLabel.Text = ""
        row.ScoreLabel.Text = ""
    end

    Events.ReceiveTopScores.OnClientEvent:Connect(function(topScores)
        for i, score in ipairs(topScores) do
            print(i, score)
            local row = Rows:FindFirstChild("Row" .. i)
            if row then
                row.RankLabel.Text = i
                row.NameLabel.Text = score.value.name
                row.ScoreLabel.Text = score.value.points
            end
        end

        print(topScores)
    end)

    Events.RequestTopScores:FireServer()
end

initRankingUI()
TopLevelContainer.Visible = true
