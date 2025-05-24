local PlayerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
local NotificationScreen = PlayerGui:WaitForChild("NotificationScreen")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = ReplicatedStorage:WaitForChild("Events")
local TopLevelContainer = NotificationScreen:WaitForChild("TopLevelContainer")

local NotificationService = {}

local confirmationBoxInitialized = false
local decide = Instance.new("BindableEvent")

local DEFAULT_DELAY = 3

-- Store the current notification task so we can cancel it
local currentNotificationTask = nil

function colorFromColorText(colorText)
    if colorText == "red" then
        return Color3.fromRGB(255, 0, 0)
    elseif colorText == "green" then
        return Color3.fromRGB(0, 255, 0)
    elseif colorText == "yellow" then
        return Color3.fromRGB(255, 255, 0)
    elseif colorText == "blue" then
        return Color3.fromRGB(0, 162, 255)
    end

    return Color3.fromRGB(0, 255, 0)
end

function NotificationService:ShowNotification(message, color, delay)
    -- Cancel any existing notification task
    if currentNotificationTask then
        task.cancel(currentNotificationTask)
        currentNotificationTask = nil
    end
    
    if delay == nil then
        delay = DEFAULT_DELAY
    end

    -- Create new notification task
    currentNotificationTask = task.spawn(function()
        if color == nil then
            color = "green"
        end

        local notification = TopLevelContainer:WaitForChild("Notification")
        notification.BackgroundColor3 = colorFromColorText(color)
        notification.Text = message
        notification.Visible = true
        
        -- Wait for the specified delay
        task.wait(delay)
        
        -- Only hide if this task hasn't been cancelled
        if currentNotificationTask == coroutine.running() then
            notification.Visible = false
            currentNotificationTask = nil
        end
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

Events.ShowNotification.OnClientEvent:Connect(function(message, color, delay)
    NotificationService:ShowNotification(message, color, delay)
end)

Events.ShowConfirmationBox.OnClientEvent:Connect(function(message)
    NotificationService:ShowConfirmationBox(message)
end)

return NotificationService