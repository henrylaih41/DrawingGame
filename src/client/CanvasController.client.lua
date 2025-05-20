local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConstants = require(ReplicatedStorage.Modules.GameData.GameConstants)
local LocalPlayer = game:GetService("Players").LocalPlayer
local ClientState = require(LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("ClientState"))
local Events = ReplicatedStorage:WaitForChild("Events")
local CommonHelper = require(ReplicatedStorage.Modules.Utils.CommonHelper)
local CollectionService = game:GetService("CollectionService")
local NotificationService = require(ReplicatedStorage.Modules.Utils.NotificationService)
local stopRendering = false
local initialized = false

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

local function initCanvas(instance)
    ClientState.DrawingCanvas[instance] = {
        imageData = nil,
        rendered = false,
        editableImage = nil,
        playerId = nil,
        canvasId = nil
    }

    local likeButton = instance:FindFirstChildWhichIsA("ImageButton", true)
    ClientState.DrawingCanvas[instance].likeButton = likeButton

    if likeButton then
        likeButton.Activated:Connect(function()
            -- Check if the drawing is empty.
            if ClientState.DrawingCanvas[instance].canvasId == nil or 
               ClientState.DrawingCanvas[instance].playerId == nil then
                NotificationService:ShowNotification("You cannot like an empty drawing.", "red")
                return
            end

            -- Check if the drawing is already liked.
            if table.find(ClientState.likedDrawings, 
                ClientState.DrawingCanvas[instance].canvasId) then
                NotificationService:ShowNotification("You already liked this drawing.", "red")
                return
            end

            -- Add the drawing to the liked drawings.
            table.insert(ClientState.likedDrawings, 
                ClientState.DrawingCanvas[instance].canvasId)

            -- TODO: Implement the like functionality.

            -- Update the like button color.
            likeButton.BackgroundColor3 = Color3.fromRGB(100, 161, 231)
        end)
    end
end

local function clearCanvas(canvas)
    ClientState.DrawingCanvas[canvas].imageData = nil
    ClientState.DrawingCanvas[canvas].playerId = nil
    ClientState.DrawingCanvas[canvas].canvasId = nil
end

local function init()
    -- We can't assume that all canvases are added to the workspace immediately.
    -- So we need to listen for the instance added signal.
    CollectionService:GetInstanceAddedSignal("Canvas"):Connect(function(c)
        initCanvas(c)
    end)

    -- In case we missed any canvases, we can add them to the state.
    for _, c in pairs(CollectionService:GetTagged("Canvas")) do
        initCanvas(c)
    end

    -- We simple set the image data for the canvas.
    -- The rendering will be handled in a separate thread.
    Events.DrawToCanvas.OnClientEvent:Connect(function(
        imageData: {ImageBuffer: buffer, ImageResolution: Vector2, Width: number, Height: number}, 
        metadata: {themeName: string, canvas: Instance, playerId: string, drawingId: string})
        local canvas = metadata.canvas

        -- Every time a new drawing is drawn, we reset the like button color.
        local likeButton = ClientState.DrawingCanvas[canvas].likeButton

        if likeButton then
            likeButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        end

        CommonHelper.unrenderCanvas(ClientState, canvas)
        -- Set the image data for the canvas.
        if imageData then
            ClientState.DrawingCanvas[canvas].imageData = imageData
            ClientState.DrawingCanvas[canvas].playerId = metadata.playerId
            ClientState.DrawingCanvas[canvas].canvasId = metadata.drawingId
        else
            clearCanvas(canvas)
        end
    end)

    initialized = true
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
    if not initialized then
        return
    end

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
                CommonHelper.renderToCanvas(ClientState, job.canvas, data)
            elseif job.op == "unrender" and data.rendered then
                CommonHelper.unrenderCanvas(ClientState, job.canvas)
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

        if not stopRendering then
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local moved = not hrpLastPos or (hrp.Position - hrpLastPos).Magnitude > 0
                hrpLastPos = hrp.Position

                for canvas, data in pairs(ClientState.DrawingCanvas) do
                    -- Safety check to ensure the canvas is not nil
                    if canvas.PrimaryPart == nil then
                        continue
                    end
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
        end

        warn(CommonHelper.getEditableImageMemoryUsage())
        task.wait(RENDER_CHECK_INTERVAL)
    end
end

function stopRenderingCanvas()
    stopRendering = true
    for canvasModel, _ in pairs(ClientState.DrawingCanvas) do 
        CommonHelper.unrenderCanvas(ClientState, canvasModel)
    end
    -- Clean the queue.
    queue = {}
end

function resumeRenderingCanvas()
    stopRendering = false
end

-- Create a bindable function to expose these functions to other client scripts
local CanvasControllerBindable = Instance.new("BindableFunction")
CanvasControllerBindable.Name = "CanvasControllerFunction"
CanvasControllerBindable.Parent = LocalPlayer.PlayerScripts

-- Handle the function calls with different action names
CanvasControllerBindable.OnInvoke = function(action)
    if action == "StopRendering" then
        stopRenderingCanvas()
    elseif action == "ResumeRendering" then
        resumeRenderingCanvas()
    end
end

task.spawn(renderCanvasController)

init()