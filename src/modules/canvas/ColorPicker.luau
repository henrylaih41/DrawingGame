--[[

Color Picker - By Trinkance

You are free to use and edit this resource for your needs

https://devforum.roblox.com/t/2577233

--]]

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local UIS        = game:GetService("UserInputService")
local DebugUtils = require(ReplicatedStorage.Modules.Services.DebugUtils) -- Added: Import DebugUtils
local InputUtils = require(ReplicatedStorage.Modules.Utils.InputUtils) -- Added: Import InputUtils
local DebugFlag = true
local firstWheelSelect = true
-- Debug logging function using DebugUtils
--- Logs a message to the console if DebugFlag is enabled.
--- @param ... any The message parts to log.
local function log(...) -- Renamed and updated function signature
    if DebugFlag then
        DebugUtils.print("ColorPicker:", ...) -- Updated: Use DebugUtils.print
    end
end



local Color = {}
Color.__index = Color

export type ParameterStyle = {
	Color: Color3?,
	Transparency: number?,
}

export type Parameters = {
	Position: UDim2?,
	RoundedCorners: number?,
	Draggable: boolean?,
	ZIndex: number?,
	Size: number?,

	Primary: ParameterStyle?,
	Secondary: ParameterStyle?,
	Topbar: ParameterStyle?,
	Text: ParameterStyle?,
}

function toPolar(v)
	return math.atan2(v.Y,v.X),v.Magnitude
end

function radToDeg(x)
	return ((x + math.pi) / (2 * math.pi)) * 360
end

function getScreenGuiWorldDetails(gui)
	local part = gui.Parent
	if gui.Face == Enum.NormalId.Front then
		return part.Position + part.CFrame.LookVector * part.Size.Z / 2,part.CFrame.LookVector
	elseif gui.Face == Enum.NormalId.Back then
		return part.Position + part.CFrame.LookVector * -part.Size.Z / 2,-part.CFrame.LookVector
	elseif gui.Face == Enum.NormalId.Right then
		return part.Position + part.CFrame.RightVector * part.Size.X / 2,part.CFrame.RightVector
	elseif gui.Face == Enum.NormalId.Left then
		return part.Position + part.CFrame.RightVector * -part.Size.X / 2,-part.CFrame.RightVector
	elseif gui.Face == Enum.NormalId.Top then
		return part.Position + part.CFrame.UpVector * part.Size.Y / 2,part.CFrame.UpVector
	elseif gui.Face == Enum.NormalId.Bottom then
		return part.Position + part.CFrame.UpVector * -part.Size.Y / 2,-part.CFrame.UpVector
	end
end

function template(tab,t)
	tab = (tab and (typeof(tab) == "table")) and tab or {}
	for i,v in pairs(t) do
		if tab[i] == nil or (typeof(v) == "table") then
			tab[i] = (typeof(v) == "table") and template(tab[i] or {},v) or v
		end
	end

	return tab
end

function roundToHundredths(num)
	return math.round(num * 100) / 100
end

-- Create a new color picker
function Color.New(gui : LayerCollector,params : Parameters?)
	if gui:IsA("SurfaceGui") then
		assert(gui.Face == Enum.NormalId.Front,"Color Picker - SurfaceGui must have it's Face property set to 'Front' to work properly")
	end
	
	local defaultPos = gui:IsA("ScreenGui") and (UserInputService:GetMouseLocation() + Vector2.new(16,-20)) or Vector2.zero
	params = template(params,{
		Position = UDim2.fromOffset(defaultPos.X,defaultPos.Y),
		RoundedCorners = true,
		ZIndex = 1,
		Size = 0.4,
		
		Primary = {Color = Color3.fromRGB(26,26,36),Transparency = 0},
		Secondary = {Color = Color3.fromRGB(36,36,46),Transparency = 0},
		Text = {Color = Color3.fromRGB(255,255,255),Transparency = 0}
	})
	
	local self = setmetatable({},Color)
	self.Params = params
	self.Gui = gui
	
	self.Connections = {}

	local ColorPicker = gui:WaitForChild("ColorPickerContainer"):WaitForChild("ColorPicker")
	
	self:Create(ColorPicker)
	self:SetColor(Color3.fromRGB(255,255,255))
	
	return self
end

function Color:Create(ColorPicker)
	log("Creating ColorPicker")
	-- Drag
	-- Events
	self.Updated = ColorPicker.UpdateEvent.Event
	self.Finished = ColorPicker.FinishedEvent.Event
	self.Canceled = ColorPicker.CanceledEvent.Event
	
	-- Value
	local valueSlider = ColorPicker.Content.Right.Value
	
	-- Update visual color and transparency
	local function _updateVisual(tab,params)
		for i,v in pairs(tab) do
			for q,e in pairs(params) do
				v[q] = e
			end
		end
	end

	for i,v in pairs(ColorPicker:GetDescendants()) do
		if not self.Params.RoundedCorners and v:IsA("UICorner") and v.Parent.Name ~= "Select" then
			v:Destroy()
		end

		if v:IsA("TextLabel") or v:IsA("TextBox") or v:IsA("ImageButton") then
			v[(v:IsA("TextLabel") or v:IsA("TextBox")) and "TextColor3" or "ImageColor3"] = self.Params.Text.Color
			v[(v:IsA("TextLabel") or v:IsA("TextBox")) and "TextTransparency" or "ImageTransparency"] = self.Params.Text.Transparency
		end
	end
	
	-- Wheel
	local wheel = ColorPicker.Content.Wheel

	self.Connections.wheelDrag = InputUtils.bindDrag(wheel.Button, function(pointerPos: Vector2) -- Updated: Use InputUtils.bindDrag
		if firstWheelSelect then
			firstWheelSelect = false
			valueSlider.Select.Position = UDim2.fromScale(0, 0)
			self.Value = 1
		end

		local wheelMid   = wheel.Image.AbsolutePosition + wheel.Image.AbsoluteSize / 2
		local toWheelMid = (pointerPos - wheelMid) / wheel.Image.AbsoluteSize
		if toWheelMid.Magnitude > 0.5 then         -- clamp to circle rim
			toWheelMid = toWheelMid.Unit / 2
		end

		wheel.Image.Select.Position = UDim2.fromScale(0.5 + toWheelMid.X,
													0.5 + toWheelMid.Y)

		-- convert to HSV
		local phi, len  = toPolar(toWheelMid * Vector2.new(1, -1))
		local hue       = math.clamp(radToDeg(phi) / 360, 0, 1)
		local sat       = math.clamp(len * 2,              0, 1)

		self.Hue        = hue
		self.Saturation = sat
		self:UpdateColorVisual()
	end)

	self.Connections.valueDrag = InputUtils.bindDrag(valueSlider.Button, function(pointerPos: Vector2) -- Updated: Use InputUtils.bindDrag
		local valueTop = valueSlider.AbsolutePosition
		local v = 1 - math.clamp(
			(pointerPos.Y - valueTop.Y) / valueSlider.AbsoluteSize.Y, 0, 1)

		self.Value = v
		valueSlider.Select.Position = UDim2.fromScale(0, 1 - v)
		self:UpdateColorVisual()
	end)

	-- Properties
	for i,v in pairs(ColorPicker.Properties.RGB:GetChildren()) do
		if v:IsA("Frame") then
			v.Frame.TextBox.FocusLost:Connect(function()
				self:SetColor(Color3.fromRGB(
					math.clamp(tonumber(ColorPicker.Properties.RGB.R.Frame.TextBox.Text) or 255,0,255),
					math.clamp(tonumber(ColorPicker.Properties.RGB.G.Frame.TextBox.Text) or 255,0,255),
					math.clamp(tonumber(ColorPicker.Properties.RGB.B.Frame.TextBox.Text) or 255,0,255)
				))
			end)
		end
	end
	
	self.Instance = ColorPicker
	return ColorPicker
end

-- Return the mouse position of the player relative to the parent GUI
function Color:GetMousePos()
	local mousePos = UserInputService:GetMouseLocation()
	local guiInset = GuiService:GetGuiInset()
	return mousePos - Vector2.new(0, guiInset.Y)
end

-- Updates the properties and color preview
function Color:UpdateColorVisual()
	if self.Instance then
		local color = Color3.fromHSV(self.Hue,self.Saturation,self.Value)
		self.Instance.UpdateEvent:Fire(color)
		
		self.Instance.Content.Right.Value.UIGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0,Color3.fromHSV(self.Hue,self.Saturation,1)),
			ColorSequenceKeypoint.new(1,Color3.fromRGB(0,0,0))
		})
		
		self.Instance.Properties.RGB.R.Frame.TextBox.Text = math.floor(color.R * 255)
		self.Instance.Properties.RGB.G.Frame.TextBox.Text = math.floor(color.G * 255)
		self.Instance.Properties.RGB.B.Frame.TextBox.Text = math.floor(color.B * 255)
	end
end

-- Sets the color and repositions the wheel and value sliders
function Color:SetColor(c : Color3)
	if self.Instance then
		local h,s,v = c:ToHSV()
		self.Saturation = s
		self.Value = v
		self.Hue = h
		
		local h2 = h * math.pi * 2
		local wv = Vector2.new(-math.cos(h2) / 2 * s,math.sin(h2) / 2 * s)
		self.Instance.Content.Wheel.Image.Select.Position = UDim2.fromScale(0.5 + wv.X,0.5 + wv.Y)
	
		
		self:UpdateColorVisual()
	end
end

-- Disconnects all current connections and destroys the window
function Color:Destroy()
	for i,v in pairs(self.Connections) do
		if typeof(v) == "RBXScriptConnection" then
			v:Disconnect()
		end
	end
	
	if self.Connections.wheelDrag then
		self.Connections.wheelDrag()
		self.Connections.wheelDrag = nil
	end
	
	if self.Connections.valueDrag then
		self.Connections.valueDrag()
		self.Connections.valueDrag = nil
	end
end

return Color