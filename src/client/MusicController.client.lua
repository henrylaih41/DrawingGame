local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")
local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local MainMenuScreen = PlayerGui:WaitForChild("MainMenuScreen")
local TopLevelContainer = MainMenuScreen:WaitForChild("TopLevelContainer")
local Buttons = TopLevelContainer:WaitForChild("Buttons")
local MusicButton = Buttons:WaitForChild("MusicButton")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Modules.GameData.GameConfig)

local musicList = {
    85418388556403,
    105963244441032,
    120082953920099,
    112102147017134 
}

local musicOffIcon = "rbxassetid://92140537053579"
local musicOnIcon = "rbxassetid://99699304490144"

local isPlaying = true

local currentTrackIndex = math.random(1, #musicList)

local bgMusic = Instance.new("Sound")
bgMusic.Looped = false -- Important for playlist looping
bgMusic.Volume = GameConfig.MUSIC_VOLUME
bgMusic.Parent = SoundService

local function playNextTrack()
    bgMusic.SoundId = "rbxassetid://" .. musicList[currentTrackIndex]
    bgMusic:Play()

    -- Prepare index for next track
    currentTrackIndex = currentTrackIndex + 1
    if currentTrackIndex > #musicList then
        currentTrackIndex = 1 -- loop back to first track
    end
end

-- Listen for track completion
bgMusic.Ended:Connect(playNextTrack)

MusicButton.Activated:Connect(function()
    isPlaying = not isPlaying
    if isPlaying then
        MusicButton.Image = musicOnIcon
        bgMusic.Volume = GameConfig.MUSIC_VOLUME
    else
        MusicButton.Image = musicOffIcon
        bgMusic.Volume = 0
    end
end)

-- Start the first track
playNextTrack()