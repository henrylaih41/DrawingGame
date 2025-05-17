local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CanvasDraw = require(ReplicatedStorage.Modules.Canvas.CanvasDraw)
local CanvasDisplay = require(ReplicatedStorage.Modules.Canvas.CanvasDisplay)
local GameConfig = require(ReplicatedStorage.Modules.GameData.GameConfig)

local GalleryCanvas = {}-- Function to set up the Best-Scores scrolling frame completely in SCALE units

function GalleryCanvas.setupGalleryCanvas(parentContainer, containers, closeButtonCallback)
    --------------------------------------------------
    -- 1. Create top bar for title and close button
    --------------------------------------------------
    local topBar = Instance.new("Frame")
    topBar.Name = "TopBar"
    topBar.Size = UDim2.new(1, 0, 0.1, 0)
    topBar.Position = UDim2.new(0, 0, 0, 0)
    topBar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    topBar.BorderSizePixel = 0
    topBar.ZIndex = 10
    topBar.Parent = parentContainer
    
    -- Add title to top bar
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(0.8, 0, 0.8, 0)
    titleLabel.Position = UDim2.new(0.1, 0, 0.1, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.Text = string.format("Best Drawings (Top %d)", GameConfig.TOP_PLAYS_LIMIT)
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.ZIndex = 11
    titleLabel.Parent = topBar
    
    -- Add close button to top bar
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0.08, 0, 0.8, 0)
    closeButton.Position = UDim2.new(1, 0, 0.1, 0)
    closeButton.AnchorPoint = Vector2.new(1, 0)
    closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeButton.BorderSizePixel = 0
    closeButton.Text = "X"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.GothamBold
    closeButton.ZIndex = 11
    
    -- Add corner rounding to the button
    local cornerRounding = Instance.new("UICorner")
    cornerRounding.CornerRadius = UDim.new(0.5, 0)
    cornerRounding.Parent = closeButton
    
    
    closeButton.Parent = topBar
    
    --------------------------------------------------
    -- 2.  Basic scrolling frame (now positioned below top bar)
    --------------------------------------------------
    local scoreScrollFrame = Instance.new("ScrollingFrame")
    scoreScrollFrame.Name = "ScoreScrollFrame"
    scoreScrollFrame.Size = UDim2.new(1, 0, 0.9, 0)
    scoreScrollFrame.Position = UDim2.new(0, 0, 0.1, 0)
    scoreScrollFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    scoreScrollFrame.BackgroundTransparency = 0.5
    scoreScrollFrame.BorderSizePixel = 0
    scoreScrollFrame.ScrollBarThickness = 6
    scoreScrollFrame.ScrollingDirection = Enum.ScrollingDirection.Y
    scoreScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y -- canvas grows for us
    scoreScrollFrame.Active = true

    scoreScrollFrame.Parent = parentContainer
    
    local BestScoreContainer = ReplicatedStorage:WaitForChild("UI"):WaitForChild("BestScoreContainer")
    --------------------------------------------------
    -- 3.  Layout maths (all in scale)
    --------------------------------------------------
    local template          = BestScoreContainer            -- keep original
    local itemsPerRow       = 3
    local paddingScale      = 0.01                          -- 2 % gap on both axes

    -- Width in scale for each cell after padding is removed.
    --  total horizontal padding = (itemsPerRow + 1) * paddingScale
    --  so usable width          = 1 - totalPadding
    local cellWidthScale    = (1 - paddingScale * (itemsPerRow + 1)) / itemsPerRow

    -- Derive an aspect ratio from the template so the height isn't zero
    local aspect            = 1                              -- fallback aspect
    if template.Size.X.Offset ~= 0 and template.Size.Y.Offset ~= 0 then
        aspect = template.Size.Y.Offset / template.Size.X.Offset
    elseif template.Size.X.Scale ~= 0 then
        aspect = template.Size.Y.Scale  / template.Size.X.Scale
    end

    local cellHeightOffset = cellWidthScale * scoreScrollFrame.AbsoluteSize.X

    --------------------------------------------------
    -- 4.  Grid layout that uses ONLY scale
    --------------------------------------------------
    local grid                  = Instance.new("UIGridLayout")
    grid.FillDirection          = Enum.FillDirection.Horizontal
    grid.SortOrder              = Enum.SortOrder.LayoutOrder
    grid.CellPadding            = UDim2.new(paddingScale, 0, paddingScale, 0)
    grid.CellSize               = UDim2.new(cellWidthScale, 0, 0, cellHeightOffset)
    grid.HorizontalAlignment    = Enum.HorizontalAlignment.Center
    grid.Parent                 = scoreScrollFrame

    --------------------------------------------------
    -- 5.  Create empty containers for each theme
    --------------------------------------------------
    for i = 1, GameConfig.TOP_PLAYS_LIMIT do
        local container = template:Clone()
        container.Name  = ("ThemeContainer_%s"):format(tostring(i))
        -- Set the parent so we initialize this container faster.
        container.Parent = scoreScrollFrame

        local arConstraint = Instance.new("UIAspectRatioConstraint")
        arConstraint.AspectRatio = aspect
        arConstraint.Parent      = container

        -- Wait for the container to be fully created
        while container.AbsoluteSize.X == 0 do
            task.wait(0.1)
        end

        local canvasFrame = container:FindFirstChild("CanvasFrame")
        local canvas = CanvasDraw.new(canvasFrame, Vector2.new(math.ceil(canvasFrame.AbsoluteSize.X), math.ceil(canvasFrame.AbsoluteSize.Y)))
        canvas.AutoRenderFpsLimit = 1
        containers[i] = {container = container, canvas = canvas}
    end

    if closeButtonCallback then
        closeButton.MouseButton1Click:Connect(closeButtonCallback, containers)
    else
        closeButton.MouseButton1Click:Connect(function()
            parentContainer.Visible = false
        end)
    end

    return scoreScrollFrame
end

function GalleryCanvas.updateDrawingDisplayForRank(drawingData, rank, containers)
    local container = containers[rank].container
    local canvas = containers[rank].canvas
    local label = container:FindFirstChild("TopBar"):FindFirstChild("BestScoreTitle")

    -- Hide the loading
    local Loading = container:FindFirstChild("CanvasFrame"):FindFirstChild("Loading")
    Loading.Visible = false
    container.Visible = false
    -- Update the container with drawing data if available
    -- If there is no previous scores, the drawingData will be nil
    if drawingData and drawingData.imageData then
        local title = drawingData.theme
        if drawingData.theme_difficulty then
            title = title .. " [" .. drawingData.theme_difficulty .. "]"
        end
        label.Text = title
        -- 1. Fetch the containerFrames and other UI elements
        local trophyContainer = container:FindFirstChild("TrophyFrame"):FindFirstChild("TrophyContainer")
        -- 2. Display the drawing
        CanvasDisplay.displayDrawingData(canvas, drawingData.imageData)
        -- 3. Update the star rating
        CanvasDisplay.updateStarDisplay(trophyContainer, drawingData.score, false)
        container.Visible = true
    end
end

function GalleryCanvas.closeDrawingDisplayForRank(rank, containers)
    local container = containers[rank].container
    -- Hide the loading
    local Loading = container:FindFirstChild("CanvasFrame"):FindFirstChild("Loading")
    Loading.Visible = false
    container.Visible = false
end

return GalleryCanvas