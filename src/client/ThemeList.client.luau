local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LeaderBoardBuilder = require(ReplicatedStorage.Modules.Utils.LeaderBoardBuilder)
local GameConfig = require(ReplicatedStorage.Modules.GameData.GameConfig)
local GameConstants = require(ReplicatedStorage.Modules.GameData.GameConstants)

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
    row.DifficultyLabel.Text = ""
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

local function getDifficultyValue(difficulty)
    if difficulty == "Easy" then
        return 1
    elseif difficulty == "Medium" then
        return 2
    elseif difficulty == "Hard" then
        return 3
    else
        return 4  -- For any unknown difficulty, place at the end
    end
end

local function sortThemesByDifficulty(themeList)
    table.sort(themeList, function(a, b)
        local diffA = getDifficultyValue(a.value.Difficulty)
        local diffB = getDifficultyValue(b.value.Difficulty)
        
        -- First sort by difficulty
        if diffA ~= diffB then
            return diffA < diffB
        end
        
        -- Then sort by name within same difficulty
        return a.value.Name < b.value.Name
    end)
    return themeList
end

local function removeDuplicateThemes(themeList)
    local uniqueThemes = {}
    local seen = {}
    
    for _, theme in ipairs(themeList) do
        -- Create a unique key based on name and difficulty
        local key = theme.value.Name .. ":" .. theme.value.Difficulty
        
        -- Only keep themes we haven't seen before
        if not seen[key] then
            seen[key] = true
            table.insert(uniqueThemes, theme)
        end
    end
    
    return uniqueThemes
end

local function initRankingUI()
    local row_per_page = ROWS_PER_PAGE
    local pageCount = math.ceil(MAX_ROWS / row_per_page)
    local prevBtn, nextBtn, closeBtn, pageLbl, pageLayout 
        = LeaderBoardBuilder.Create(TopLevelContainer, MAX_ROWS, createRow, createFooter, row_per_page)


    local currentPage = 1
    updateLabel(pageLbl, currentPage, pageCount)

    closeBtn.MouseButton1Click:Connect(function()
        ThemeListScreen.Enabled = false
        TopLevelContainer.Visible = false
        Events.ClientStateChange:FireServer(GameConstants.PlayerStateEnum.IDLE)
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
    header.NameLabel.Text = "Theme"
    header.DifficultyLabel.Text = "Difficulty"
    header.DurationLabel.Text = "Duration"
    Events.ReceiveThemeListPage.OnClientEvent:Connect(function(themeList)
        -- Remove duplicates and sort themes by difficulty and name before displaying
        themeList = removeDuplicateThemes(themeList)
        themeList = sortThemesByDifficulty(themeList)
        warn("ThemeList", themeList)
        
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
                    row.DifficultyLabel.Text = theme.Difficulty
                    
                    -- Set color based on difficulty
                    if theme.Difficulty == "Easy" then
                        row.DifficultyLabel.TextColor3 = Color3.fromRGB(0, 255, 0)  -- Green
                    elseif theme.Difficulty == "Medium" then
                        row.DifficultyLabel.TextColor3 = Color3.fromRGB(255, 255, 0)  -- Yellow
                    elseif theme.Difficulty == "Hard" then
                        row.DifficultyLabel.TextColor3 = Color3.fromRGB(255, 0, 0)  -- Red
                    else
                        row.DifficultyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)  -- White (default)
                    end
                    
                    row.DurationLabel.Text = theme.Duration
                    row:SetAttribute("theme_uuid", theme.uuid)
                end
            end
        end
    end)

    Events.GameStateChanged.OnClientEvent:Connect(function(stateData)
        if stateData.state == GameConstants.PlayerStateEnum.THEME_LIST then
            ThemeListScreen.Enabled = true
            TopLevelContainer.Visible = true
        else
            ThemeListScreen.Enabled = false
            TopLevelContainer.Visible = false
        end
    end)

    -- First page start key is nil.
    Events.RequestThemeListPage:FireServer()
    print("ThemeList initialized")
end

initRankingUI()