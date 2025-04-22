local UIS = game:GetService("UserInputService")

local InputUtils = {}

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
	assert(typeof(dragButton) == "Instance" and dragButton:IsA("GuiObject"), "InputUtils.bindDrag expects dragButton to be a GuiObject")
	assert(typeof(onMove) == "function", "InputUtils.bindDrag expects onMove to be a function")

	local connection = dragButton.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then

			local dragInput = input  -- store so we only follow *this* finger/mouse

			-- do an initial update immediately
			onMove(InputUtils.toViewportPos(input.Position))

			-- follow the pointer while it moves
			local moveCn, endCn
			moveCn = UIS.InputChanged:Connect(function(changed)
				if changed == dragInput then
					onMove(InputUtils.toViewportPos(changed.Position))
				end
			end)

			-- stop when that pointer ends
			endCn = UIS.InputEnded:Connect(function(ended)
				if ended == dragInput then
					if moveCn then moveCn:Disconnect() end
					if endCn then endCn:Disconnect() end
				end
			end)
		end
	end)
	-- Return the connection so it can be disconnected later if needed
	return connection
end


return InputUtils 