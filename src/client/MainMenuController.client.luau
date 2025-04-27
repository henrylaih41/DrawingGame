local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Utils = Modules:WaitForChild("Utils")
local ButtonEffects = require(Utils:WaitForChild("ButtonEffects"))
local Players= game:GetService("Players")

-- Get references to UI elements
local PlayerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
local MainMenuScreen = PlayerGui:WaitForChild("MainMenuScreen")
local TopLevelContainer = MainMenuScreen:WaitForChild("TopLevelContainer")
local Buttons = TopLevelContainer:WaitForChild("Buttons")
local SinglePlayerButton = Buttons:WaitForChild("SinglePlayerButton")

-- Set up events
local Events = ReplicatedStorage:WaitForChild("Events")
local StartGameEvent = Events:WaitForChild("StartGame")
local GameStateChangedEvent = Events:WaitForChild("GameStateChanged")

-- Game state constants
local GameState = {
    MAIN_MENU = "MAIN_MENU",
    COUNTDOWN = "COUNTDOWN",
    DRAWING = "DRAWING",
    GRADING = "GRADING",
    VOTING = "VOTING",
    RESULTS = "RESULTS"
}

-- Function to handle SinglePlayer button click
local function onSinglePlayerClicked()
    print("Single Player mode selected")
    -- Fire event to GameManager with game mode parameter
    StartGameEvent:FireServer("SinglePlayer")
end

-- Function to handle MultiPlayer button click
local function onMultiPlayerClicked()
    print("Multi-Player mode selected")
    -- Fire event to GameManager with game mode parameter
    StartGameEvent:FireServer("MultiPlayer")
end

-- Function to handle game state changes
local function onGameStateChanged(stateData)
    if stateData and stateData.state then
        print("Game state changed to:", stateData.state)
        
        -- Show main menu only when in MAIN_MENU state, hide otherwise
        if stateData.state == GameState.MAIN_MENU then
            TopLevelContainer.Visible = true
        else
            TopLevelContainer.Visible = false
        end
    end
end

-- Connect button click events
SinglePlayerButton.MouseButton1Click:Connect(onSinglePlayerClicked)

-- Apply button effects
local cleanupFunctions = {}
table.insert(cleanupFunctions, ButtonEffects.applyHoverEffects(SinglePlayerButton, onSinglePlayerClicked))

-- Connect game state event
GameStateChangedEvent.OnClientEvent:Connect(onGameStateChanged)

-- Initialize the controller
local function initialize()
    local LocalPlayer = Players.LocalPlayer
    local pModule = require(LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
    local playerControls = pModule:GetControls()
    playerControls:Disable()
    print("MainMenuController initialized")
end

-- Cleanup function for when this controller is no longer needed
local function cleanup()
    for _, cleanupFunc in ipairs(cleanupFunctions) do
        cleanupFunc()
    end
    
    -- Disconnect game state event if we stored the connection
    -- If we did store it, we would disconnect it here
end

initialize()

-- Return cleanup function if needed by a parent system
return cleanup 