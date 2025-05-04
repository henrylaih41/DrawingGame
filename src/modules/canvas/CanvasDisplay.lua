local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ImageDataConstructor = require(ReplicatedStorage.Modules.Canvas.ImageDataConstructor)
local DebugUtils = require(ReplicatedStorage.Modules.Services.DebugUtils)
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local CanvasDisplay = {}
local DebugFlag = false

-- Debug logging function using DebugUtils
--- Logs a message to the console if DebugFlag is enabled.
--- @param ... any The message parts to log.
local function log(...)
    if DebugFlag then
        DebugUtils.print("CanvasDisplay:", ...)
    end
end

-- Sound effect for trophy appearance
local TROPHY_SOUND_ID = "rbxassetid://111277558339395"
local HIGH_SCORE_SOUND_ID = "rbxassetid://79723856625266" -- Add a celebration sound for high scores
local soundsFolder = ReplicatedStorage:FindFirstChild("Sounds")
assert(soundsFolder ~= nil, "Sounds folder not found in ReplicatedStorage")

local trophySound = Instance.new("Sound")
trophySound.SoundId = TROPHY_SOUND_ID
trophySound.Volume = 0.5
trophySound.Parent = soundsFolder

local highScoreSound = Instance.new("Sound")
highScoreSound.SoundId = HIGH_SCORE_SOUND_ID
highScoreSound.Volume = 0.7
highScoreSound.Parent = soundsFolder

-- Function to play trophy sound with pitch variation
local function playTrophySound(pitch)
    -- Clone the sound so multiple can play simultaneously
    local sound = trophySound:Clone()
    sound.Parent = workspace
    sound.PlaybackSpeed = pitch or 1
    sound:Play()
    
    -- Clean up sound after it finishes playing
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
end

-- Function to play high score celebration sound
local function playHighScoreSound()
    local sound = highScoreSound:Clone()
    sound.Parent = workspace
    sound:Play()
    
    -- Clean up sound after it finishes playing
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
end

-- Function to create a starburst effect
local function createStarburstEffect(parent)
    for i = 1, 8 do
        local spark = Instance.new("Frame")
        spark.BorderSizePixel = 0
        spark.BackgroundColor3 = Color3.fromRGB(255, 255, 150) -- Yellow spark
        spark.Size = UDim2.new(0, 2, 0, 10)
        spark.AnchorPoint = Vector2.new(0.5, 0.5)
        spark.Position = UDim2.new(0.5, 0, 0.5, 0)
        spark.Rotation = i * 45 -- Evenly spaced around
        spark.ZIndex = 10 -- Ensure it appears above the trophy
        spark.Parent = parent
        
        -- Create glow effect
        local uiGradient = Instance.new("UIGradient")
        uiGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 200, 50))
        })
        uiGradient.Parent = spark
        
        -- Animate the spark outward
        local tweenInfo = TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = TweenService:Create(spark, tweenInfo, {
            Size = UDim2.new(0, 2, 0, 40),
            BackgroundTransparency = 1
        })
        tween:Play()
        
        -- Clean up after animation
        tween.Completed:Connect(function()
            spark:Destroy()
        end)
    end
end

-- Function to display an image from ImageData
--- Clears the target canvas and draws the provided image data onto it, scaling to fit.
--- @param targetCanvas CanvasDraw The CanvasDraw instance to draw on.
--- @param imageData table The image data containing Width, Height, and ImageBuffer.
function CanvasDisplay.displayDrawingData(targetCanvas, imageData)
    assert(targetCanvas ~= nil, "Canvas is nil")
    assert(imageData ~= nil, "ImageData is nil")
    assert(imageData.Width ~= nil and imageData.Height ~= nil and imageData.ImageBuffer ~= nil, "Invalid ImageData structure")

    -- Clear any existing content
    targetCanvas:Clear()
    local reconstructedImage =
        ImageDataConstructor.new(imageData.Width, imageData.Height, imageData.ImageBuffer)
    local scaleX = targetCanvas.Resolution.X / reconstructedImage.Width
    local scaleY = targetCanvas.Resolution.Y / reconstructedImage.Height
    targetCanvas:DrawImage(reconstructedImage, Vector2.new(1, 1), Vector2.new(scaleX, scaleY))
end

function CanvasDisplay.clearStarDisplay(trophyContainer)
    assert(trophyContainer ~= nil, "Trophy container is nil")
    for i = 1, 10 do
        local trophy = trophyContainer:WaitForChild("Trophy" .. i)
        assert(trophy ~= nil, "Trophy" .. i .. " not found in TrophyContainer")
        local overlay = trophy:WaitForChild("show")
        local uiScale = overlay.UIScale
        uiScale.Scale = 0
    end
end

--- Function to update the star display based on score
--- Updates the star images (empty/filled) based on the provided score.
--- Handles potential issues with finding star ImageLabels.
--- @param score number The score (0-10) determining the number of filled stars.
function CanvasDisplay.updateStarDisplay(trophyContainer, score, animated)
    log("Updating star display for score: ", score)
    assert(type(score) == "number" and score >= 0 and score <= 10, "Score must be a number between 0 and 10 " .. score)
    assert(trophyContainer ~= nil, "Trophy container is nil")
    -- Populate stars table
    local trophies = {}
    for i = 1, 10 do
        local trophy = trophyContainer:WaitForChild("Trophy" .. i)
        assert(trophy ~= nil, "Trophy" .. i .. " not found in TrophyContainer")
        assert(trophy:IsA("Frame"), "Trophy" .. i .. " must be an Frame")
        table.insert(trophies, trophy)
    end
    assert(#trophies == 10, "Expected 10 trophies, found " .. #trophies)

    if not animated then
        for i = 1, #trophies do
            local trophy = trophies[i]
            local overlay = trophy:WaitForChild("show")
            local uiScale = overlay.UIScale
            overlay.Visible = true
            uiScale.Scale = 0
            if i <= score then
                uiScale.Scale = 1
            end
        end
        trophyContainer.Visible = true -- Ensure container is visible
        return 
    end
    
    -- Animate trophies sequentially
    for i = 1, #trophies do
        local trophy = trophies[i]
        local overlay = trophy:WaitForChild("show")
        local uiScale = overlay.UIScale
        overlay.Visible = true
        -- Initialize the values
        uiScale.Scale = 0
        if i <= score then
            task.delay((i - 1) * 0.3, function()
                -- Play sound with pitch variation based on trophy position
                -- Higher pitch for higher value trophies
                local pitch = 0.8 + (i * 0.05)
                playTrophySound(pitch)
                
                -- Animation for appearing with a bounce effect using UIScale
                local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                local tween = TweenService:Create(uiScale, tweenInfo, {Scale = 1})
                tween:Play()

                task.delay(0.5, function()
                    task.delay(0.2, function()
                        createStarburstEffect(overlay)
                    end)
                end)
            end)
        end
    end
    
    -- Play a special celebration sound after all trophies have appeared if score is high
    if score >= 8 then
        -- Calculate delay based on the number of trophies (each takes 0.3s to appear)
        -- Add extra delay for the starburst effects and final trophy to complete
        local totalDelay = (score * 0.3) + 0.7
        task.delay(totalDelay, function()
            playHighScoreSound()
        end)
    end

    trophyContainer.Visible = true -- Ensure container is visible
end

return CanvasDisplay 