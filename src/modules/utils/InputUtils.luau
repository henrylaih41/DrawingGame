local UIS = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DebugUtils  = require(ReplicatedStorage.Modules.Services.DebugUtils)
local GameConfig = require(ReplicatedStorage.Modules.GameData.GameConfig)
local InputUtils = {}

local DebugFlag = GameConfig.DEBUG_INPUTUTILS
local function log(...)
    if DebugFlag then DebugUtils.print("DrawingCanvas:", ...) end
end
-- Normalise a screen‑space point → Vector2, minus top‑bar inset.
-- Note: This function currently doesn't account for the top-bar inset.
-- Consider adding GuiService:GetGuiInset() if needed for ScreenGuis.
function InputUtils.toViewportPos(rawPos: Vector3)
	-- rawPos is typically InputObject.Position
	assert(typeof(rawPos) == "Vector3", "InputUtils.toViewportPos expects a Vector3")
	return Vector2.new(rawPos.X, rawPos.Y)
end

-- Generic "drag" binder: handles both mouse and single‑finger touch.
--  • dragButton : GuiObject that starts the drag
--  • onMove(fn) : (Vector2 viewportPos) → ()
function InputUtils.bindDrag(dragButton: GuiObject, onMove)
    assert(typeof(dragButton) == "Instance" and dragButton:IsA("GuiObject"), "...")
    assert(typeof(onMove) == "function", "...")

    local dragging = false                 -- works for every device

    local beginCn = dragButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
           or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            onMove(InputUtils.toViewportPos(input.Position))
        end
    end)

    local moveCn = UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                         or input.UserInputType == Enum.UserInputType.Touch) then
            onMove(InputUtils.toViewportPos(input.Position))
        end
    end)

    local endCn = UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
           or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    -- let caller clean up all three connections with one call
    return function() beginCn:Disconnect(); moveCn:Disconnect(); endCn:Disconnect() end
end



return InputUtils 