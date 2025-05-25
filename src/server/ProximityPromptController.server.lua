local CollectionService = game:GetService("CollectionService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerConfig = require(ServerScriptService.modules.ServerConfig)
local ServerStates = require(ServerScriptService.modules.ServerStates)
local GameConstants = require(ReplicatedStorage.Modules.GameData.GameConstants)
local Events = ReplicatedStorage:WaitForChild("Events")
local PPS = game:GetService("ProximityPromptService")
local CanvasManager = require(ServerScriptService.modules.CanvasManager)

-- Attach drawing prompts to the canvas
local function attachDrawingPrompts(canvasModel)
    local board = canvasModel:FindFirstChild("CanvasFrame")
    if not board or board:FindFirstChildWhichIsA("ProximityPrompt") then return end

    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "RegisterCanvasPrompt"
    prompt.RequiresLineOfSight   = false
    prompt.HoldDuration          = ServerConfig.PROMPT.HOLD_DURATION
    prompt.MaxActivationDistance = ServerConfig.PROMPT.MAX_ACTIVATION_DISTANCE
    prompt.ActionText            = "Claim"   -- we'll show our own SurfaceGui
    prompt.ObjectText            = "Canvas"
    prompt.Parent = board

    CollectionService:AddTag(prompt, "CanvasPrompt")
end

local TELEPORT_DISTANCE = ServerConfig.PROMPT.TELEPORT_DISTANCE   -- studs in front of the board
local TELEPORT_HEIGHT   = ServerConfig.PROMPT.TELEPORT_HEIGHT    -- studs up

local function teleportPlayerToCanvas(player, canvasModel)
    local char = player.Character
    if not (char and char.PrimaryPart) then return end

    -- ① choose a reference CFrame
    local boardCF, boardSize
    local board = canvasModel.PrimaryPart          -- assumes you set it
    if not board then return end
    boardCF   = board.CFrame
    boardSize = board.Size

    -- ② move outwards from the board's front face
    local forward = boardCF.LookVector
    local offset  = forward * (boardSize.Z/2 + TELEPORT_DISTANCE)
    local pos     = boardCF.Position + offset + Vector3.new(0, TELEPORT_HEIGHT, 0)

    -- ③ face the board
    local cf      = CFrame.new(pos, boardCF.Position)

    char:PivotTo(cf)         -- atomic, physics-safe move
end

local function initialize()
    local displayCanvasList = CollectionService:GetTagged("DisplayCanvas")
    -- existing canvases
    for _, c in pairs(CollectionService:GetTagged("Canvas")) do
        -- Skip the canvases that are used for display
        if table.find(displayCanvasList, c) then
            continue
        end
        attachDrawingPrompts(c)
    end

    PPS.PromptTriggered:Connect(function(prompt, player)
        if prompt.Name == "RegisterCanvasPrompt" then
            
            -- Check if the player has reached the maximum number of owned canvas.
            if ServerStates.PlayerState[player].maximumOwnedCanvas <= 
               #ServerStates.PlayerState[player].ownedCanvas then
                Events.ShowNotification:FireClient(player,
                    "Reach maximum canvas limit, unregister owned canvas first")
                return
            end

            local canvas = prompt.Parent.Parent
            -- If it is registered, return. This only occurs if two players try to register to the same canvas.
            -- TODO: Still might be a race condition here.
            if ServerStates.CanvasState[canvas].registered then
                return
            end

            -- Register the canvas.
            ServerStates.CanvasState[canvas].registered = true
            ServerStates.CanvasState[canvas].ownerPlayer = player

            -- Update the player state.
            table.insert(ServerStates.PlayerState[player].ownedCanvas, canvas)

            -- Close the register prompt.
            local registerPrompt = canvas:FindFirstChild("CanvasFrame"):FindFirstChild("RegisterCanvasPrompt")
            registerPrompt.Enabled = false

            -- Notify the client that the canvas has been registered.
            Events.RegisterCanvas:FireClient(player, canvas)
        else 
            warn("Unknown prompt triggered", prompt.Name)
        end
    end)

    Events.DrawCanvas.OnServerEvent:Connect(function(player, canvas)
        if ServerStates.CanvasState[canvas].ownerPlayer ~= player then
            warn("DrawCanvas triggered by non-owner player")
            return
        end
        -- -- Teleport the player to the canvas.
        -- teleportPlayerToCanvas(player, canvas)
    end)

    Events.UnregisterCanvas.OnServerEvent:Connect(function(player, canvas)
        if ServerStates.CanvasState[canvas].ownerPlayer ~= player then
            warn("UnregisterCanvasPrompt triggered by non-owner player")
            return
        end

        -- remove the canvas from the player's ownedCanvas.
        local ownedCanvasList = ServerStates.PlayerState[player].ownedCanvas
        for i, ownedCanvas in ipairs(ownedCanvasList) do
            if ownedCanvas == canvas then
                table.remove(ownedCanvasList, i)
                break
            end
        end
        
        -- Unregister the canvas.
        CanvasManager.resetCanvas(canvas)

        -- Notify the client that the canvas has been unregistered.
        Events.UnregisterCanvas:FireClient(player, canvas)
    end)
end

initialize()