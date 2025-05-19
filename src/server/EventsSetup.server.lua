-- EventsSetup.server.lua
-- Creates all necessary RemoteEvents for the game

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create Events folder
local Events = Instance.new("Folder")
Events.Name = "Events"

-- Function to create an event if it doesn't exist
local function createEvent(name)
    local existingEvent = Events:FindFirstChild(name)
    if not existingEvent then
        local newEvent = Instance.new("RemoteEvent")
        newEvent.Name = name
        newEvent.Parent = Events
        print("Created RemoteEvent: " .. name)
    end
end

-- Create all needed events
createEvent("DrawingsReceived")
createEvent("GameStateChanged")
createEvent("GameCountdown")
createEvent("PlayerDataUpdated")
createEvent("PlayerReady")
createEvent("SubmitDrawing")
createEvent("startDrawing")
createEvent("SubmitVote")
createEvent("ShowResults")
createEvent("ReturnToMainMenu")
createEvent("ReceiveNewBestDrawing")
createEvent("RequestTopPlays")
createEvent("RequestTopScores")
createEvent("ReceiveTopPlays")
createEvent("ReceiveTopScores")
createEvent("RequestThemeListPage")
createEvent("ReceiveThemeListPage")
createEvent("UpdateLobbyPlayers")
createEvent("SendFeedback")
createEvent("AdminCommand")
createEvent("TestEvent")
createEvent("RegisterCanvas")
createEvent("UnregisterCanvas")
createEvent("DrawCanvas")
createEvent("ClientStateChange")
createEvent("DrawToCanvas")
createEvent("ShowNotification")
createEvent("ShowConfirmationBox")
createEvent("DeleteGalleryDrawing")
createEvent("SaveToGallery")
-- Set the parent of the Events folder
Events.Parent = ReplicatedStorage
print("Events setup complete") 