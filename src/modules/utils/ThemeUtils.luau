local ThemeUtils = {}

--- Returns the trophy multiplier based on difficulty.
function ThemeUtils.getTrophyMultiplier(difficulty: string): number
    if difficulty == "Easy" then
        return 1
    elseif difficulty == "Medium" then
        return 2
    elseif difficulty == "Hard" then
        return 3
    else
        return 1
    end
end

--- Returns a numeric value for sorting difficulties.
function ThemeUtils.getDifficultyValue(difficulty: string): number
    if difficulty == "Easy" then
        return 1
    elseif difficulty == "Medium" then
        return 2
    elseif difficulty == "Hard" then
        return 3
    else
        return 4
    end
end

--- Sorts a list of themes by difficulty and name.
function ThemeUtils.sortThemesByDifficulty(themeList)
    table.sort(themeList, function(a, b)
        local diffA = ThemeUtils.getDifficultyValue(a.Difficulty)
        local diffB = ThemeUtils.getDifficultyValue(b.Difficulty)
        if diffA ~= diffB then
            return diffA < diffB
        end
        return a.Name < b.Name
    end)
    return themeList
end

--- Removes duplicate themes from a list.
function ThemeUtils.removeDuplicateThemes(themeList)
    local uniqueThemes = {}
    local seen = {}
    for _, theme in ipairs(themeList) do
        local key = theme.Name .. ":" .. theme.Difficulty
        if not seen[key] then
            seen[key] = true
            table.insert(uniqueThemes, theme)
        end
    end
    return uniqueThemes
end

return ThemeUtils
