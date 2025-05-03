--------------------------------------------------------------------
-- LeaderboardBuilder.lua
--   Builds a paged, scrollable leaderboard UI
--
--   API:
--     LeaderboardBuilder.Create(
--         TopLevelContainer : Instance,   -- parent frame
--         totalRows         : number,     -- how many rows of data exist
--         createRow         : (number) -> Frame  -- user-supplied row factory
--     )
--------------------------------------------------------------------
local LeaderboardBuilder = {}

--------------------------------------------------------------------
-- DEFAULT CONSTANTS -------------------------------------------------------
--------------------------------------------------------------------
local ROWS_PER_PAGE = 20
local TOPBAR_HEIGHT_SCALE  = 0.05   -- 10 % of container height
local HEADER_HEIGHT_SCALE  = 0.06   --  6 %
local topBarColor = Color3.fromRGB(30,30,30)
local btnTextColor = Color3.fromRGB(255,255,255)
local pageLblTextColor = Color3.fromRGB(255,255,255)
local headerTransparency = 0
local headerBackgroundColor = Color3.fromRGB(40,40,40)
--------------------------------------------------------------------
-- PUBLIC ----------------------------------------------------------
--------------------------------------------------------------------
function LeaderboardBuilder.Create(container, totalRows, createRow, rowPerPage, topBarHeightScale, headerHeightScale)
    assert(typeof(container) == "Instance", "Pass a valid TopLevelContainer")
    assert(typeof(totalRows) == "number"   and totalRows > 0, "totalRows must be > 0")
    assert(typeof(createRow) == "function", "createRow(name) must be a function")
    local topBarHeightScale = topBarHeightScale or TOPBAR_HEIGHT_SCALE
    local headerHeightScale = headerHeightScale or HEADER_HEIGHT_SCALE
    local rowPerPage = rowPerPage or ROWS_PER_PAGE
    local pageAreaScale = 1 - topBarHeightScale - headerHeightScale*2
    local rowHeightScale = headerHeightScale -- row height is the same as the header height

    ----------------------------------------------------------------
    -- 1. TOP BAR ---------------------------------------------------
    ----------------------------------------------------------------
    local topBar = Instance.new("Frame")
    topBar.Name  = "TopBar"
    topBar.Size  = UDim2.new(1, 0, topBarHeightScale, 0)
    topBar.BackgroundColor3 = topBarColor
    topBar.Parent = container

    local topBarGroup = Instance.new("Frame")
    topBarGroup.Name = "TopBarGroup"
    topBarGroup.Size = UDim2.new(0.9,0,1,0)
    topBarGroup.AnchorPoint = Vector2.new(0, 0.5)
    topBarGroup.Position = UDim2.new(0, 0, 0.5, 0)
    topBarGroup.BackgroundTransparency = 1
    topBarGroup.Parent = topBar

    -- HUD controls inside the top bar
    local prevBtn  = Instance.new("TextButton")
    local pageLbl  = Instance.new("TextLabel")
    local nextBtn  = Instance.new("TextButton")

    for _, btn in ipairs({prevBtn, nextBtn}) do
        btn.TextScaled = true
        btn.Font       = Enum.Font.SourceSansBold
        btn.BackgroundTransparency = 1
        btn.Size       = UDim2.new(0.12, 0, 0.8, 0) -- 12 % wide, 80 % tall
        btn.AnchorPoint= Vector2.new(0, 0.5)
        btn.Position   = UDim2.new(0, 0, 0.5, 0)
        btn.TextColor3 = btnTextColor 
        btn.Parent     = topBarGroup
    end

    prevBtn.Name, prevBtn.Text = "PrevButton", "<"
    nextBtn.Name, nextBtn.Text = "NextButton", ">"

    pageLbl.Name        = "PageLabel"
    pageLbl.TextScaled  = true
    pageLbl.Font        = Enum.Font.SourceSansBold
    pageLbl.BackgroundTransparency = 1
    pageLbl.Size        = UDim2.new(0.24, 0, 0.8, 0)  -- 24 % wide
    pageLbl.AnchorPoint = Vector2.new(0, 0.5)
    pageLbl.Position    = UDim2.new(0, 0, 0.5, 0)
    pageLbl.TextColor3  = pageLblTextColor
    pageLbl.Parent      = topBarGroup

    -- Use a horizontal UIListLayout to align the controls
    local topLayout = Instance.new("UIListLayout")
    topLayout.SortOrder = Enum.SortOrder.LayoutOrder
    topLayout.FillDirection = Enum.FillDirection.Horizontal
    topLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    topLayout.VerticalAlignment   = Enum.VerticalAlignment.Center
    topLayout.Padding      = UDim.new(0, 4)
    topLayout.Parent       = topBarGroup

    prevBtn.LayoutOrder = 1
    nextBtn.LayoutOrder = 3
    pageLbl.LayoutOrder = 2

    -- Move the close button to the top bar so it is at the far right
    local closeBtn = Instance.new("ImageButton")
    closeBtn.Image = "rbxassetid://83200145475911"
    closeBtn.Parent = topBar
    closeBtn.AnchorPoint = Vector2.new(0.5, 0.5)
    closeBtn.Position = UDim2.new(0.975, 0, 0.5, 0)
    closeBtn.Size = UDim2.new(0.05, 0, 0.8, 0)
    closeBtn.BackgroundTransparency = 1
    closeBtn.ZIndex = 100

    ----------------------------------------------------------------
    -- 2. HEADER ----------------------------------------------------
    ----------------------------------------------------------------
    local header = createRow("Header")
    header.Parent = container
    header.Position = UDim2.new(0,0,topBarHeightScale,0)
    header.Size = UDim2.new(1,0,headerHeightScale,0)
    header.BorderSizePixel = 1
    header.BackgroundTransparency = headerTransparency
    header.BackgroundColor3 = headerBackgroundColor 

    ----------------------------------------------------------------
    -- 3. PAGE CONTAINER & PAGES -----------------------------------
    ----------------------------------------------------------------
    local pageContainer = Instance.new("Frame")
    pageContainer.Name  = "PageContainer"
    pageContainer.Size  = UDim2.new(1, 0, pageAreaScale, 0)
    pageContainer.Position = UDim2.new(0,0,topBarHeightScale + headerHeightScale, 0)
    pageContainer.BackgroundTransparency = header.BackgroundTransparency
    pageContainer.BackgroundColor3 = header.BackgroundColor3
    pageContainer.Parent = container
    pageContainer.ClipsDescendants = true 

    local pageLayout = Instance.new("UIPageLayout")
    pageLayout.FillDirection = Enum.FillDirection.Horizontal
    pageLayout.SortOrder     = Enum.SortOrder.LayoutOrder
    pageLayout.EasingStyle   = Enum.EasingStyle.Quad
    pageLayout.TouchInputEnabled  = true
    pageLayout.GamepadInputEnabled= true
    pageLayout.Parent         = pageContainer

    -- Make pages
    local pageCount = math.ceil(totalRows / rowPerPage)
    local rowIndex  = 1
    for p = 1, pageCount do
        local pageFrame = Instance.new("ScrollingFrame")
        pageFrame.Name  = "Page_" .. p
        pageFrame.Size  = UDim2.new(1,0,1,0)
        pageFrame.ScrollBarThickness = 0
        pageFrame.CanvasSize         = UDim2.new(0,0,0,0)
        pageFrame.AutomaticCanvasSize= Enum.AutomaticSize.Y
        pageFrame.BackgroundTransparency = pageContainer.BackgroundTransparency
        pageFrame.BackgroundColor3 = pageContainer.BackgroundColor3
        pageFrame.Parent = pageContainer
        pageFrame.Active = true

        -- vertical list layout inside page
        local list = Instance.new("UIListLayout")
        list.FillDirection = Enum.FillDirection.Vertical
        list.SortOrder     = Enum.SortOrder.LayoutOrder
        list.Padding       = UDim.new(0,0)
        list.Parent        = pageFrame

        -- rows for this page
        for i = 1, math.min(rowPerPage, totalRows - (p-1)*rowPerPage) do
            local row = createRow("Row" .. i)
            rowIndex += 1
            -- Wait for header to be created.
            while (header.AbsoluteSize.Y== 0) do
                task.wait(0.1)
            end
            -- We use fixed offset for row since scrollable frame would automatically scale.
            local rowHeightOffset = header.AbsoluteSize.Y
            row.Size  = UDim2.new(1,0,0,rowHeightOffset)
            row.Parent= pageFrame
            row.BackgroundColor3 = pageFrame.BackgroundColor3
            row.BackgroundTransparency = pageFrame.BackgroundTransparency
        end
    end

    -- Player rank --
    local playerRank = createRow("PlayerRank")
    playerRank.Parent = container
    playerRank.Position = UDim2.new(0,0,1-headerHeightScale,0)
    playerRank.Size = UDim2.new(1,0,headerHeightScale,0)
    playerRank.BorderSizePixel = 1
    playerRank.BackgroundTransparency = headerTransparency
    playerRank.BackgroundColor3 = headerBackgroundColor 
    ----------------------------------------------------------------
    -- 4. BUTTON BEHAVIOUR -----------------------------------------
    ----------------------------------------------------------------
    local currentPage = 1
    local function updateLabel()
        pageLbl.Text = string.format("%d / %d", currentPage, pageCount)
    end
    updateLabel()

    prevBtn.MouseButton1Click:Connect(function()
        if currentPage > 1 then
            currentPage -= 1
            pageLayout:JumpToIndex(currentPage - 1)
            updateLabel()
        end
    end)

    nextBtn.MouseButton1Click:Connect(function()
        if currentPage < pageCount then
            currentPage += 1
            pageLayout:JumpToIndex(currentPage - 1)
            updateLabel()
        end
    end)

    closeBtn.MouseButton1Click:Connect(function()
        container.Visible = false
    end)
end

return LeaderboardBuilder
