local PlayerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
local NotificationScreen = PlayerGui:WaitForChild("NotificationScreen")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = ReplicatedStorage:WaitForChild("Events")
local TopLevelContainer = NotificationScreen:WaitForChild("TopLevelContainer")
local NotificationService = {}

local confirmationBoxInitialized = false
local decide = Instance.new("BindableEvent")

function NotificationService:ShowNotification(message)
    task.spawn(function()
        local notification = TopLevelContainer:WaitForChild("Notification")
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

Events.ShowNotification.OnClientEvent:Connect(function(message)
    NotificationService:ShowNotification(message)
end)

Events.ShowConfirmationBox.OnClientEvent:Connect(function(message)
    NotificationService:ShowConfirmationBox(message)
end)

return NotificationService
