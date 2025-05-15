local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConstants = require(ReplicatedStorage.Modules.GameData.GameConstants)
local LocalPlayer = game:GetService("Players").LocalPlayer
local ClientState = require(LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("ClientState"))
local Events = ReplicatedStorage:WaitForChild("Events")
local AssetService = game:GetService("AssetService")
local CommonHelper = require(ReplicatedStorage.Modules.Utils.CommonHelper)

local function GetDeviceTier()
    local screenSize = workspace.CurrentCamera.ViewportSize

    if screenSize.X >= 1920 then
        return "High"
    elseif screenSize.X >= 1280 then
        return "Medium"
    else
        return "Low"
    end
end

local function createEditableImage(size: Vector2)
    warn("Creating editable image", size)
    local editableImage = AssetService:CreateEditableImage({Size = size})
    CommonHelper.addEditableImageMemoryUsage(editableImage)
    return editableImage
end

local function destroyEditableImage(editableImage: EditableImage)
    if editableImage then
        CommonHelper.substractEditableImageMemoryUsage(editableImage)
        editableImage:Destroy()
    end
end

local function unrenderCanvas(canvas: Model)
    destroyEditableImage(ClientState.DrawingCanvas[canvas].editableImage)
    ClientState.DrawingCanvas[canvas].rendered = false
end

local function init()
    for _, c in ipairs(workspace:WaitForChild(GameConstants.DrawingCanvasFolderName):GetChildren()) do

        ClientState.DrawingCanvas[c] = {
            imageData = nil,
            rendered = false,
            editableImage = nil
        }
    end

    -- We simple set the image data for the canvas.
    -- The rendering will be handled in a separate thread.
    Events.DrawToCanvas.OnClientEvent:Connect(function(
        imageData: {ImageBuffer: buffer, ImageResolution: Vector2, Width: number, Height: number}, 
        currentTheme: string, 
        canvas)
        -- Set the image data for the canvas.
        if imageData then
            unrenderCanvas(canvas)
            ClientState.DrawingCanvas[canvas].imageData = imageData
        else
            -- When we set the image data to nil, we should also unrender the canvas.
            ClientState.DrawingCanvas[canvas].imageData = nil
            unrenderCanvas(canvas)
        end

        warn("DrawToCanvas", imageData, currentTheme, canvas)

        -- Let's Render the image immediately for now. 
        -- TODO: We should add our own rendering system so we only render image close to the players.
        -- Create the editable from the original image data.
    end)
end

local function renderToCanvas(canvas: Model, data: {imageData: {ImageBuffer: buffer, ImageResolution: Vector2, Width: number, Height: number}, rendered: boolean})
    local imageData = data.imageData
    local imageLabel = canvas.PrimaryPart:FindFirstChild("CanvasGui"):FindFirstChild("DrawingImage")
    local imageResolution = imageData.ImageResolution or Vector2.new(imageData.Width, imageData.Height)
    local src = createEditableImage(imageResolution)

    -- If we can't create the editable image, we should return.
    if src == nil then
        return
    end

    local dest = createEditableImage(imageLabel.AbsoluteSize) 

    -- If we can't create the editable image, we should return.
    if dest == nil then
        destroyEditableImage(src)
        return
    end

    src:WritePixelsBuffer(Vector2.zero, imageResolution, imageData.ImageBuffer)
    local scale = Vector2.new(imageLabel.AbsoluteSize.X / imageResolution.X, imageLabel.AbsoluteSize.Y / imageResolution.Y)
    dest:DrawImageTransformed(
        Vector2.zero,                         -- put TOP‑LEFT at (0,0)
        scale,                                -- shrink
        0,                                    -- no rotation
        src,
        { PivotPoint = Vector2.zero, CombineType = Enum.ImageCombineType.Overwrite } )
    -- Destroy the source editable image to release memory.
    destroyEditableImage(src)
    -- render the image .
    imageLabel.ImageContent = Content.fromObject(dest)
    -- Store this so we can destroy it later.
    ClientState.DrawingCanvas[canvas].editableImage = dest
    data.rendered = true
end

-- ░░ adjustable knobs ░░ ------------------------------------
local RENDER_RADIUS        = GameConstants.RENDER_RADIUS
local UNRENDER_RADIUS      = GameConstants.UNRENDER_RADIUS
local RENDER_CHECK_INTERVAL = 1          -- scan canvases every N s
local OPS_PER_STEP         = 2          -- max renders per Heartbeat
local OPS_PER_SECOND       = 6          -- global cap (helps low-end GPUs)
--------------------------------------------------------------

-- small utility --------------------------------------------------------------
local RunService = game:GetService("RunService")
local clock      = os.clock              -- micro-precision timer

----------------------------------------------------------------
-- 1  A queue that holds tasks:   { canvas = <Instance>, op = "render"|"unrender" }
----------------------------------------------------------------
local queue = {}                         -- FIFO
local opsThisSecond, windowStart = 0, clock()

local function enqueue(canvas, op, dist)
    if op == "render" then
        queue[#queue+1] = {canvas = canvas, op = op, dist = dist or math.huge}
    else                                -- unrender / other work
        queue[#queue+1] = {canvas = canvas, op = op}
    end
end

----------------------------------------------------------------
-- 2  Consumer: runs every frame, but respects both caps
----------------------------------------------------------------
RunService.Heartbeat:Connect(function()
    -- reset the 1-second window
    local now = clock()
    if now - windowStart >= 1 then
        opsThisSecond, windowStart = 0, now
    end

    if #queue > 1 then
        table.sort(queue, function(a, b)
            -- 1) Always prioritise render over unrender
            if a.op ~= b.op then
                return a.op == "render"
            end
            -- 2) For two render jobs, smaller distance wins
            if a.op == "render" then
                return a.dist < b.dist
            end
            -- 3) For two unrender jobs, keep FIFO order
            return false
        end)
    end

    local opsThisStep = 0
    while opsThisStep < OPS_PER_STEP
          and opsThisSecond < OPS_PER_SECOND
          and #queue > 0
    do
        local job = table.remove(queue, 1)        -- pop first (FIFO)
        local data = ClientState.DrawingCanvas[job.canvas]
        if data then
            if job.op == "render"   and not data.rendered and data.imageData then
                renderToCanvas(job.canvas, data)
            elseif job.op == "unrender" and data.rendered then
                unrenderCanvas(job.canvas)
            end
        end
        opsThisStep   += 1
        opsThisSecond += 1
    end
end)

----------------------------------------------------------------
-- 3  Producer: same distance-scan you already had, but push jobs instead of executing them
----------------------------------------------------------------
local function renderCanvasController()
    local hrpLastPos = nil

    while true do
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local moved = not hrpLastPos or (hrp.Position - hrpLastPos).Magnitude > 0
            hrpLastPos = hrp.Position

            for canvas, data in pairs(ClientState.DrawingCanvas) do
                -- recalc only if player moved OR render-state mismatches data
                if moved or (data.rendered ~= (data.imageData ~= nil)) then
                    local dist = (hrp.Position - canvas.PrimaryPart.Position).Magnitude

                    if dist <= RENDER_RADIUS then
                        if data.imageData and not data.rendered then
                            enqueue(canvas, "render", dist)          -- pass priority
                        end
                    elseif dist >= UNRENDER_RADIUS then
                        if data.rendered then
                            enqueue(canvas, "unrender")              -- no need for dist
                        end
                    end
                end
            end
        end

        warn(CommonHelper.getEditableImageMemoryUsage())
        task.wait(RENDER_CHECK_INTERVAL)
    end
end

task.spawn(renderCanvasController)

init()