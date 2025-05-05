local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LeaderBoardBuilder = require(ReplicatedStorage.Modules.Utils.LeaderBoardBuilder)
local GameConfig = require(ReplicatedStorage.Modules.GameData.GameConfig)

-- Get references to UI elements
local PlayerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
local ThemeListScreen = PlayerGui:WaitForChild("ThemeListScreen")
local TopLevelContainer = ThemeListScreen:WaitForChild("TopLevelContainer")
local rowTemplate = ReplicatedStorage:WaitForChild("UI"):WaitForChild("ThemeListRow")
local footerTemplate = ReplicatedStorage:WaitForChild("UI"):WaitForChild("ThemeListFooter")

-- TODO: Fixed size for now, will need to scale this in the future.
local MAX_ROWS = GameConfig.THEME_LIST_LIMIT 
local ROWS_PER_PAGE = GameConfig.THEME_LIST_ROWS_PER_PAGE

-- Set up events
local Events = ReplicatedStorage:WaitForChild("Events")
local SelectedTheme = nil

local function createRow(name)
    local row = rowTemplate:Clone()
    local YOffset = TopLevelContainer.AbsoluteSize.Y * rowTemplate.Size.Y.Scale
    row.Size = UDim2.new(1, 0, 0, YOffset)
    row.Name = name
    row.NameLabel.Text = ""
    row.DescriptionLabel.Text = ""
    row.DurationLabel.Text = ""
    return row
end

local function resetSelectedTheme(frame)
    if frame then
        local selectButton = frame:FindFirstChild("SelectButton")
        selectButton.BackgroundTransparency = 1
    end
end

local function createFooter()
    local footer = footerTemplate:Clone()
    local YOffset = TopLevelContainer.AbsoluteSize.Y * rowTemplate.Size.Y.Scale
    footer.Size = UDim2.new(1, 0, 0, YOffset)
    footer.Name = "Footer"
    local drawButton = footer:FindFirstChild("DrawButton")
    drawButton.MouseButton1Click:Connect(function()
        -- If no theme is selected, do nothing.
        if not SelectedTheme then
            return
        end
        local theme_uuid = SelectedTheme:GetAttribute("theme_uuid")
        Events.StartGame:FireServer(theme_uuid)
        resetSelectedTheme(SelectedTheme)
        -- Entering drawing phase, hide the theme list.
        TopLevelContainer.Visible = false
        SelectedTheme = nil
    end)
    return footer
end

local function updateLabel(pageLbl, currentPage, pageCount)
    pageLbl.Text = string.format("%d / %d", currentPage, pageCount)
end

local function selectTheme(row)
    -- If same theme is selected, do nothing.
    if SelectedTheme == row then
        return
    end
    resetSelectedTheme(SelectedTheme)
    -- Select the new theme.
    SelectedTheme = row
end

local function initRankingUI()
    local row_per_page = ROWS_PER_PAGE
    local pageCount = math.ceil(MAX_ROWS / row_per_page)
    local prevBtn, nextBtn, pageLbl, pageLayout 
        = LeaderBoardBuilder.Create(TopLevelContainer, MAX_ROWS, createRow, createFooter, row_per_page)


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
    header.NameLabel.Text = "Theme"
    header.DescriptionLabel.Text = "Description"
    header.DurationLabel.Text = "Duration"
    Events.ReceiveThemeListPage.OnClientEvent:Connect(function(themeList)
        warn(themeList)
        warn(#themeList)
        local pageFrame = nil 
        for i, theme in ipairs(themeList) do
            theme = theme.value
            local page_index = math.ceil(i / row_per_page)
            local row_index = i - (page_index - 1) * row_per_page
            pageFrame = pageContainer:FindFirstChild("Page_" .. page_index)
            if pageFrame then
                local row = pageFrame:FindFirstChild("Row" .. row_index)
                if row then
                    local selectButton = Instance.new("TextButton")
                    selectButton.Name = "SelectButton"
                    selectButton.Text = ""
                    selectButton.Size = UDim2.new(1, 0, 1, 0)
                    selectButton.Position = UDim2.new(0, 0, 0, 0)
                    selectButton.Parent = row
                    selectButton.BackgroundTransparency = 1
                    selectButton.ZIndex = 0

                    selectButton.MouseButton1Click:Connect(function()
                        selectButton.BackgroundTransparency = 0
                        selectButton.BackgroundColor3 = GameConfig.SELECTED_COLOR 
                        selectTheme(row)
                    end)

                    row.NameLabel.Text = theme.Name
                    row.DescriptionLabel.Text = theme.Description
                    row.DurationLabel.Text = theme.Duration
                    row:SetAttribute("theme_uuid", theme.uuid)
                end
            end
        end
    end)

    -- First page start key is nil.
    Events.RequestThemeListPage:FireServer()
end

initRankingUI()