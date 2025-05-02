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
createEvent("GameStateChanged")
createEvent("UpdateLobbyPlayers")
createEvent("PlayerReady")
createEvent("StartGame")
createEvent("GameCountdown")
createEvent("SubmitDrawing")
createEvent("DrawingsReceived")
createEvent("SubmitVote")
createEvent("ShowResults")
createEvent("ReturnToMainMenu")
createEvent("RequestBestDrawings")
createEvent("ReceiveBestDrawings")
createEvent("ReceiveNewBestDrawing")
createEvent("PlayerDataUpdated")

-- Set the parent of the Events folder
Events.Parent = ReplicatedStorage
print("Events setup complete") 