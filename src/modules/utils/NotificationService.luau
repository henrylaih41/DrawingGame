local PlayerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
local NotificationScreen = PlayerGui:WaitForChild("NotificationScreen")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = ReplicatedStorage:WaitForChild("Events")
local TopLevelContainer = NotificationScreen:WaitForChild("TopLevelContainer")
local NotificationService = {}

local confirmationBoxInitialized = false
local decide = Instance.new("BindableEvent")

function colorFromColorText(colorText)
    if colorText == "red" then
        return Color3.fromRGB(255, 0, 0)
    elseif colorText == "green" then
        return Color3.fromRGB(0, 255, 0)
    end

    return Color3.fromRGB(0, 255, 0)
end

function NotificationService:ShowNotification(message, color)
    task.spawn(function()
        if color == nil then
            color = "green"
        end

        local notification = TopLevelContainer:WaitForChild("Notification")
        notification.BackgroundColor3 = colorFromColorText(color)
        notification.Text = message
        notification.Visible = true
        task.wait(3)
        notification.Visible = false
    end)
end

local function initializeConfirmationBox()
    local confirmationBox = TopLevelContainer:WaitForChild("ConfirmationBox")
    local cancelButton = confirmationBox:WaitForChild("ButtonContainer"):WaitForChild("CancelButton")
    local confirmButton = confirmationBox:WaitForChild("ButtonContainer"):WaitForChild("ConfirmButton")
    cancelButton.MouseButton1Click:Connect(function()
        confirmationBox.Visible = false
        decide:Fire(false)
    end)    

    confirmButton.MouseButton1Click:Connect(function()
        confirmationBox.Visible = false
        decide:Fire(true)
    end)
end

function NotificationService:GetConfirmation()
    return decide.Event:Wait()
end

function NotificationService:ShowConfirmationBox(message)
    local confirmationBox = TopLevelContainer:WaitForChild("ConfirmationBox")
    local bodyText = confirmationBox:WaitForChild("BodyTextContainer"):WaitForChild("BodyText")
    bodyText.Text = message
    confirmationBox.Visible = true

    if not confirmationBoxInitialized then
        confirmationBoxInitialized = true
        initializeConfirmationBox()
    end
end

Events.ShowNotification.OnClientEvent:Connect(function(message, color)
    NotificationService:ShowNotification(message, color)
end)

Events.ShowConfirmationBox.OnClientEvent:Connect(function(message)
    NotificationService:ShowConfirmationBox(message)
end)

return NotificationService
