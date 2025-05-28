local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local GameConstants = require(ReplicatedStorage.Modules.GameData.GameConstants)
local GameConfig = require(ReplicatedStorage.Modules.GameData.GameConfig)
local NotificationService = require(ReplicatedStorage.Modules.Utils.NotificationService)
-- Get references to UI elements
local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local ThemeListScreen = PlayerGui:WaitForChild("ThemeListScreen")
local TopLevelContainer = ThemeListScreen:WaitForChild("TopLevelContainer")

-- Get UI components
local TitleBar = TopLevelContainer:WaitForChild("TitleBar")
local CloseButton = TitleBar:WaitForChild("CloseButton")
local ContentArea = TopLevelContainer:WaitForChild("ContentArea")

-- Difficulty section
local DifficultySection = ContentArea:WaitForChild("DifficultySection")
local DifficultyButtons = DifficultySection:WaitForChild("DifficultyButtons")

-- Theme section
local ThemeSection = ContentArea:WaitForChild("ThemeSection")
local ThemeGroupContainer = ThemeSection:WaitForChild("ThemeGroupContainer")
local ThemeGroupTabs = ThemeGroupContainer:WaitForChild("ThemeGroupTabs")
local TabsScrolling = ThemeGroupTabs:WaitForChild("TabsScrolling")
local ThemeListContainer = ThemeSection:WaitForChild("ThemeListContainer")
local ThemeScrolling = ThemeListContainer:WaitForChild("ThemeScrolling")

-- Action buttons
local ActionButtons = ContentArea:WaitForChild("ActionButtons")
local RandomButton = ActionButtons:WaitForChild("RandomButton")
local DrawButton = ActionButtons:WaitForChild("DrawButton")

-- Set up events
local Events = ReplicatedStorage:WaitForChild("Events")

-- State variables
local selectedDifficulty = nil
local selectedTheme = nil
local currentGroup = "Animals"

-- Theme configuration - single source of truth
local themeConfig = {
    Animals = {
        color = Color3.fromRGB(255, 182, 193), -- Light pink
        themes = {
            "Dog","Cat","Bird","Fish","Horse","Elephant","Lion","Tiger","Panda","Koala",
            "Giraffe","Penguin","Dolphin","Rabbit","Wolf","Bear","Fox","Monkey","Kangaroo","Zebra",
            "Owl","Shark","Turtle","Crocodile","Snake","Deer","Squirrel","Bee","Butterfly","Eagle"
        }
    },

    Objects = {
        color = Color3.fromRGB(173, 216, 230), -- Light blue
        themes = {
            "Chair","Table","Lamp","Book","Phone","Computer","Television","Camera","Guitar","Clock",
            "Backpack","Cup","Pencil","Glasses","Bottle","Microwave","Refrigerator","Washing Machine","Vacuum","Knife",
            "Spoon","Fork","Plate","Bed","Sofa","Door","Window","Remote","Headphones","Wallet"
        }
    },

    Food = {
        color = Color3.fromRGB(255, 218, 185), -- Peach
        themes = {
            "Pizza","Burger","Apple","Banana","Ice Cream","Sushi","Doughnut","Salad","Sandwich","Cookie",
            "Cake","Pasta","Taco","Fried Chicken","Chocolate","Steak","Rice","Bread","Cheese","Curry",
            "Noodles","Pancake","Burrito","Hot Dog","French Fries","Dumplings","Ramen","Waffle","Pie","Muffin"
        }
    },

    Nature = {
        color = Color3.fromRGB(152, 251, 152), -- Pale green
        themes = {
            "Tree","Flower","Mountain","River","Sun","Moon","Beach","Volcano","Waterfall","Desert",
            "Rainbow","Cloud","Forest","Lake","Canyon","Glacier","Island","Cliff","Valley","Ocean",
            "Meadow","Cave","Hill","Reef","Lightning","Storm","Aurora","Sand Dune","Geyser","Lagoon"
        }
    },

    Sports = {
        color = Color3.fromRGB(255, 160, 122), -- Light salmon
        themes = {
            "Football","Basketball","Tennis","Swimming","Baseball","Cricket","Skiing","Surfing","Boxing","Skateboarding",
            "Volleyball","Rugby","Golf","Table Tennis","Badminton","Cycling","Ice Hockey","Marathon","Diving","Gymnastics",
            "Wrestling","Archery","Karate","Snowboarding","Rowing","Sailing","Fencing","Bowling","Handball","Lacrosse"
        }
    },

    Fantasy = {
        color = Color3.fromRGB(186, 85, 211), -- Medium orchid
        themes = {
            "Dragon","Unicorn","Mermaid","Fairy","Phoenix","Wizard","Castle","Knight","Elf","Dwarf",
            "Ogre","Troll","Griffin","Werewolf","Vampire","Witch","Goblin","Centaur","Pegasus","Kraken",
            "Sorcerer","Dark Lord","Necromancer","Magic Sword","Enchanted Forest","Spell Book","Potion","Portal","Dragon Egg","Crystal Ball"
        }
    },

    Space = {
        color = Color3.fromRGB(216, 194, 231), -- Indigo
        themes = {
            "Star","Planet","Rocket","Astronaut","Galaxy","Alien","Satellite","Comet","Meteor","Black Hole",
            "Moon Rover","Space Station","Nebula","Spacesuit","Telescope","Asteroid Belt","Dwarf Planet","Supernova","Solar Panel","Alien Spaceship",
            "Mars Rover","Constellation","Eclipse","Milky Way","Wormhole","Space Shuttle","Lunar Lander","Space Probe","Quasar","Exoplanet"
        }
    },

    Holidays = {
        color = Color3.fromRGB(255, 215, 0), -- Gold
        themes = {
            "Christmas Tree","Snowman","Pumpkin","Easter Egg","Fireworks","Gift","Heart","Turkey","Santa Claus","Reindeer",
            "Candy Cane","Lantern","Shamrock","Hanukkah Menorah","Diya Lamp","Jack-o'-Lantern","Valentine's Rose","Birthday Cake","Party Hat","Graduation Cap",
            "Wedding Ring","Independence Flag","Spring Blossom","New Year Clock","Champagne","Piñata","Cherry Blossom","Lantern Festival","Bonfire","Dragon Boat"
        }
    },

    Emotions = {
        color = Color3.fromRGB(255, 105, 180), -- Hot pink
        themes = {
            "Happy Face","Sad Face","Angry Face","Surprised Face","Love","Laughing Cry","Fear","Disgust","Joy","Excitement",
            "Boredom","Confusion","Pride","Shame","Embarrassment","Awe","Hope","Relief","Anxiety","Determination",
            "Curiosity","Trust","Gratitude","Serenity","Nostalgia","Envy","Anticipation","Confidence","Loneliness","Shock"
        }
    },

    Professions = {
        color = Color3.fromRGB(70, 130, 180), -- Steel blue
        themes = {
            "Doctor","Police Officer","Firefighter","Chef","Teacher","Scientist","Artist","Engineer","Farmer","Pilot",
            "Nurse","Astronaut","Musician","Athlete","Detective","Carpenter","Plumber","Electrician","Mechanic","Librarian",
            "Baker","Photographer","Lawyer","Dentist","Vet","Soldier","Fashion Designer","Game Developer","Architect","Barista"
        }
    },

    Landmarks = {
        color = Color3.fromRGB(210, 180, 140), -- Tan
        themes = {
            "Eiffel Tower","Statue of Liberty","Great Wall","Pyramids of Giza","Big Ben","Colosseum","Taj Mahal","Sydney Opera House","Golden Gate Bridge","Mount Rushmore",
            "Leaning Tower of Pisa","Machu Picchu","Christ the Redeemer","Stonehenge","Burj Khalifa","Empire State Building","CN Tower","Sagrada Familia","Tokyo Tower","Mount Fuji",
            "Angkor Wat","Petronas Towers","Niagara Falls","Grand Canyon","Kremlin","Brandenburg Gate","Acropolis","Mount Everest","Uluru","Palace of Versailles"
        }
    },

    Characters = {
        color = Color3.fromRGB(255, 69, 0), -- Red orange
        themes = {
            "Naruto","Goku","Pikachu","Sailor Moon","Monkey D. Luffy","Tanjiro","Deku","Gojo","Anya Forger","Eren Yeager",
            "Mikasa","Levi","Ichigo","Rin Tohsaka","Light Yagami","Totoro","Doraemon","Astro Boy","Nezuko","Kirito",
            "Asuna","Saitama","Kenshin","Edward Elric","Alphonse Elric","SpongeBob","Spider-Man","Batman","Iron Man","Wonder Woman",
            "Superman","Captain America","Black Panther","Thor","Hulk","Deadpool","Sonic","Elsa","Buzz Lightyear","Shrek"
        }
    }
}

-- Helper functions to extract data from themeConfig
local function getThemeGroups()
    local groups = {}
    for groupName, config in pairs(themeConfig) do
        groups[groupName] = config.themes
    end
    return groups
end

local function getTabColors()
    local colors = {}
    for groupName, config in pairs(themeConfig) do
        colors[groupName] = config.color
    end
    return colors
end

-- Use the helper functions
local themeGroups = getThemeGroups()
local tabColors = getTabColors()

-- Store references to theme items by group
local themeItemsByGroup = {}

-- Store references to tab buttons
local tabButtons = {}

-- Function to show/hide theme items based on selected group
local function updateThemeDisplay(groupName)
    -- Hide all theme items
    for group, items in pairs(themeItemsByGroup) do
        for _, item in ipairs(items) do
            item.Visible = false
        end
    end
    
    -- Show selected group's items
    local groupItems = themeItemsByGroup[groupName]
    if groupItems then
        for _, item in ipairs(groupItems) do
            item.Visible = true
        end
    end
end

-- Function to get the color index for a theme
local function getThemeColorIndex(themeName, groupName)
    local themes = themeGroups[groupName]
    if themes then
        for i, theme in ipairs(themes) do
            if theme == themeName then
                return i
            end
        end
    end
    return 1 -- Default to first color if not found
end

-- Create all theme items at initialization
local function createAllThemeItems()
    for groupName, themes in pairs(themeGroups) do
        themeItemsByGroup[groupName] = {}
        
        for i, themeName in ipairs(themes) do
            local ThemeItem = Instance.new("TextButton")
            ThemeItem.Name = themeName .. "Item"
            ThemeItem.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            ThemeItem.Text = themeName
            ThemeItem.TextColor3 = Color3.fromRGB(50, 50, 50)
            ThemeItem.TextScaled = true
            ThemeItem.Font = Enum.Font.Cartoon
            ThemeItem.Visible = groupName == "Animals" -- Only show Animals group initially
            ThemeItem.Parent = ThemeScrolling
            
            local ItemCorner = Instance.new("UICorner")
            ItemCorner.CornerRadius = UDim.new(0.2, 0)
            ItemCorner.Parent = ThemeItem
            
            -- Store reference
            table.insert(themeItemsByGroup[groupName], ThemeItem)
            
            -- Theme selection handler
            ThemeItem.MouseButton1Click:Connect(function()
                -- Reset previous selection
                if selectedTheme then
                    -- Find the previous button across all groups
                    for gName, items in pairs(themeItemsByGroup) do
                        for idx, item in ipairs(items) do
                            if item.Name == selectedTheme .. "Item" then
                                local colorIndex = getThemeColorIndex(selectedTheme, gName)
                                item.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                                break
                            end
                        end
                    end
                end
                
                -- Set new selection
                selectedTheme = themeName
                ThemeItem.BackgroundColor3 = GameConfig.SELECTED_COLOR
            end)
        end
    end
end

-- Set up difficulty button handlers
for _, button in pairs(DifficultyButtons:GetChildren()) do
    if button:IsA("TextButton") then
        local difficulty = button.Name:gsub("Button", "")
        
        button.MouseButton1Click:Connect(function()
            -- Reset previous selection
            if selectedDifficulty then
                local prevButton = DifficultyButtons:FindFirstChild(selectedDifficulty .. "Button")
                if prevButton then
                    local difficultyColors = {
                        Easy = Color3.fromRGB(144, 238, 144),
                        Medium = Color3.fromRGB(255, 215, 0),
                        Hard = Color3.fromRGB(255, 99, 71)
                    }
                    prevButton.BackgroundColor3 = difficultyColors[selectedDifficulty]
                end
            end
            
            -- Set new selection
            selectedDifficulty = difficulty
            button.BackgroundColor3 = GameConfig.SELECTED_COLOR
        end)
    end
end

-- Function to create all group tabs dynamically (only called once)
local function createAllGroupTabs()
    -- Only create tabs if they haven't been created yet
    if next(tabButtons) ~= nil then
        return
    end
    
    -- Clear any existing tabs first
    for _, child in pairs(TabsScrolling:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    -- Count theme groups for canvas size calculation
    local groupCount = 0
    for _ in pairs(themeConfig) do
        groupCount = groupCount + 1
    end
    
    -- Create tabs for each theme group
    for groupName, config in pairs(themeConfig) do
        local TabButton = Instance.new("TextButton")
        TabButton.Name = groupName .. "Tab"
        TabButton.BackgroundColor3 = config.color
        TabButton.Text = groupName
        TabButton.TextColor3 = Color3.fromRGB(50, 50, 50)
        TabButton.TextScaled = true
        TabButton.Font = Enum.Font.Cartoon
        TabButton.Parent = TabsScrolling
        TabButton.Size = UDim2.fromScale(0.075, 1)
        
        local TabCorner = Instance.new("UICorner")
        TabCorner.CornerRadius = UDim.new(0.2, 0)
        TabCorner.Parent = TabButton
        
        -- Store reference
        tabButtons[groupName] = TabButton
        
        -- Set up click handler
        TabButton.MouseButton1Click:Connect(function()
            -- Reset previous tab
            local prevTab = tabButtons[currentGroup]
            if prevTab then
                prevTab.BackgroundColor3 = tabColors[currentGroup] or Color3.fromRGB(200, 200, 200)
            end
            
            -- Reset previously selected theme color before switching groups
            if selectedTheme then
                for gName, items in pairs(themeItemsByGroup) do
                    for idx, item in ipairs(items) do
                        if item.Name == selectedTheme .. "Item" then
                            item.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                            break
                        end
                    end
                end
            end
            
            -- Set new selection
            currentGroup = groupName
            TabButton.BackgroundColor3 = GameConfig.SELECTED_COLOR
            updateThemeDisplay(groupName)
            
            -- Reset theme selection when changing groups
            selectedTheme = nil
        end)
    end
    
    TabsScrolling.CanvasSize = UDim2.fromScale(1.5, 1)
    
    -- Set initial tab selection
    local initialTab = tabButtons["Animals"]
    if initialTab then
        initialTab.BackgroundColor3 = GameConfig.SELECTED_COLOR
    end
end

-- Draw button handler
DrawButton.MouseButton1Click:Connect(function()
    if selectedDifficulty and selectedTheme then
        Events.startDrawing:FireServer(selectedTheme, selectedDifficulty)
        
        -- Reset selections
        selectedDifficulty = nil
        selectedTheme = nil
        
        -- Close the UI
        ThemeListScreen.Enabled = false
        TopLevelContainer.Visible = false
    else
        if selectedDifficulty == nil then
            NotificationService:ShowNotification("Please select a difficulty", "red")
        elseif selectedTheme == nil then
            NotificationService:ShowNotification("Please select a theme", "red")
        end

        -- Flash the button to indicate missing selection
        local originalColor = DrawButton.BackgroundColor3
        DrawButton.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
        task.wait(0.2)
        DrawButton.BackgroundColor3 = originalColor
    end
end)

-- Random button handler
RandomButton.MouseButton1Click:Connect(function()
    -- Get all available difficulties
    local difficulties = {"Easy", "Medium", "Hard"}
    local randomDifficulty = difficulties[math.random(1, #difficulties)]
    
    -- Get all themes from all groups
    local allThemes = {}
    for _, themes in pairs(themeGroups) do
        for _, theme in ipairs(themes) do
            table.insert(allThemes, theme)
        end
    end
    
    -- Pick random theme
    local randomTheme = allThemes[math.random(1, #allThemes)]
    
    -- Send to server
    Events.startDrawing:FireServer(randomTheme, randomDifficulty)
    
    -- Close the UI
    ThemeListScreen.Enabled = false
    TopLevelContainer.Visible = false
end)

-- Close button handler
CloseButton.MouseButton1Click:Connect(function()
    ThemeListScreen.Enabled = false
    TopLevelContainer.Visible = false
    Events.ClientStateChange:FireServer(GameConstants.PlayerStateEnum.IDLE)
end)

-- Function to set default difficulty
local function setDefaultDifficulty()
    -- Set Easy as default
    selectedDifficulty = "Easy"
    local easyButton = DifficultyButtons:FindFirstChild("EasyButton")
    if easyButton then
        easyButton.BackgroundColor3 = GameConfig.SELECTED_COLOR
    end
end

-- Handle game state changes
Events.GameStateChanged.OnClientEvent:Connect(function(stateData)
    if stateData.state == GameConstants.PlayerStateEnum.THEME_LIST then
        ThemeListScreen.Enabled = true
        TopLevelContainer.Visible = true
        
        -- Show initial group
        updateThemeDisplay("Animals")
        
        -- Reset selections and set default difficulty
        selectedTheme = nil
        setDefaultDifficulty()  -- This sets Easy as default
    else
        ThemeListScreen.Enabled = false
        TopLevelContainer.Visible = false
    end
end)

-- Initialize all UI elements once
createAllGroupTabs()
createAllThemeItems()
