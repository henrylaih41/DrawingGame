local PlayerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
local NotificationScreen = PlayerGui:WaitForChild("NotificationScreen")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = ReplicatedStorage:WaitForChild("Events")
local TopLevelContainer = NotificationScreen:WaitForChild("TopLevelContainer")
local NotificationService = {}

function NotificationService:ShowNotification(message)
    task.spawn(function()
        local notification = TopLevelContainer:WaitForChild("Notification")
        notification.Text = message
        notification.Visible = true
        task.wait(3)
        notification.Visible = false
    end)
end

Events.ShowNotification.OnClientEvent:Connect(function(message)
    NotificationService:ShowNotification(message)
end)


return NotificationService
