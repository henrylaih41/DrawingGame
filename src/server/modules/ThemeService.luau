local ServerScriptService = game:GetService("ServerScriptService")
local ThemeStore = require(ServerScriptService.modules.ThemeStore)

local ThemeService = {}

function ThemeService:createTheme(
    name: string, 
    description: string, 
    gradingPrompt: string, 
    difficulty: string, 
    duration: number, 
    createdBy: string)

    local theme = ThemeStore:newTheme(
        name, description, gradingPrompt, duration, createdBy, difficulty)

    print("Loaded theme: " .. name)
    local success, _ = ThemeStore:saveTheme(theme)

    if not success then
        warn("Failed to save theme: " .. name)
        return nil
    end

    return theme
end

return ThemeService
