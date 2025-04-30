local ButtonEffects = {}

--[[
    Applies hover and press effects to a button with proper cleanup.
    
    @param button GuiObject - The button to apply effects to
    @param onClick function - Callback when button is clicked (optional)
    @param customColors table - Optional table with color overrides:
        {default: Color3?, hover: Color3?, press: Color3?}
    
    @return function - Cleanup function to disconnect all events
]]
function ButtonEffects.applyHoverEffects(button, onClick, customColors)
    customColors = customColors or {}
    local defaultColor = customColors.default or button.BackgroundColor3
    local hoverColor = customColors.hover or Color3.fromRGB(220, 220, 220)
    local pressColor = customColors.press or Color3.fromRGB(180, 180, 180)
    
    local connections = {}
    
    -- Mouse input handling
    table.insert(connections, button.MouseEnter:Connect(function()
        button.BackgroundColor3 = hoverColor
    end))
    
    table.insert(connections, button.MouseLeave:Connect(function()
        button.BackgroundColor3 = defaultColor
    end))
    
    table.insert(connections, button.MouseButton1Down:Connect(function()
        button.BackgroundColor3 = pressColor
    end))
    
    table.insert(connections, button.MouseButton1Up:Connect(function()
        button.BackgroundColor3 = hoverColor
    end))
    
    -- For both mouse and touch
    if onClick then
        table.insert(connections, button.MouseButton1Click:Connect(function()
            onClick(button)
        end))
    end
    
    -- Return disconnect function for cleanup
    return function()
        for _, connection in ipairs(connections) do
            connection:Disconnect()
        end
    end
end

function ButtonEffects.applyButtonPressEffect(button, pressImage)
    -- Store original properties
    local originalImage = button.Image

    -- Create press effect
    local function onButtonDown()
        button.Image = pressImage
    end
    
    -- Restore original appearance
    local function onButtonUp()
        button.Image = originalImage
    end
    
    -- Connect events
    local mouseDownConnection = button.MouseButton1Down:Connect(onButtonDown)
    local mouseUpConnection = button.MouseButton1Up:Connect(onButtonUp)
    local mouseLeaveConnection = button.MouseLeave:Connect(onButtonUp)
    
    -- Return cleanup function
    return function()
        mouseDownConnection:Disconnect()
        mouseUpConnection:Disconnect()
        mouseLeaveConnection:Disconnect()
    end
end

return ButtonEffects 