local DataStoreService = game:GetService("DataStoreService")
local ServerScriptService = game:GetService("ServerScriptService")
local DataStoreHelper = require(ServerScriptService.modules.DataStoreHelper)
local HttpService = game:GetService("HttpService")
local ThemeCodeStore = require(ServerScriptService.modules.ThemeCodeStore)

local ThemeStore = {}
local ThemeDataStore = DataStoreService:GetDataStore("Themes")
local ThemeDefaultCodeLength = 8
local ThemeMaxCodeLength = 12
local allThemeSummariesKey = "all_theme_summaries"

export type Theme = {
    Name: string,
    Description: string,
    GradingPrompt: string,
    Difficulty: string,
    TotalPlayCount: number,
    Duration: number,
    CreatedBy: string,
    CreatedAt: string,
    uuid: string,
    Code: string,
    -- pageID: string,
    Likes: number
}

function ThemeStore:getTheme(theme_uuid: string): Theme?
    local success, result = DataStoreHelper:_performDataStoreOperationWithRetry(
        ThemeDataStore,
        "GetAsync",
        "Theme_" .. theme_uuid,
        nil,
        true
    )   

    if success and result then
        return result
    end

    return nil
end 

local function makeThemeSummary(theme: Theme)
    local themeSummary = {
        uuid = theme.uuid,
        Name = theme.Name,
        Description = theme.Description:sub(1, 300),
        CreatedBy = theme.CreatedBy,
        TotalPlayCount = theme.TotalPlayCount,
        CreatedAt = theme.CreatedAt,
        Duration = theme.Duration,
        Difficulty = theme.Difficulty,
        Likes = theme.Likes,
        Code = theme.Code
    }

    return themeSummary
end

function ThemeStore:getUniqueCode(theme_uuid: string)
    local code_length: number = ThemeDefaultCodeLength
    local code: string = theme_uuid:sub(1, code_length)

    while (not ThemeCodeStore:checkCodeNotExists(code)) do  
        code_length = code_length + 1
        code = theme_uuid:sub(1, code_length)
        -- Let's not go too crazy. Might be a bug so break.
        if code_length > ThemeMaxCodeLength then
            error("Failed to generate unique code for theme: " .. theme_uuid)
            return nil
        end
    end

    return code
end

function ThemeStore:saveTheme(theme: Theme)

    local success, _ = DataStoreHelper:_performDataStoreOperationWithRetry(
        ThemeDataStore,
        "SetAsync",
        "Theme_" .. theme.uuid,
        theme,
        true
    )

    if success then
        -- Store the code to uuid mapping.
        local code_success, _ = ThemeCodeStore:saveThemeCode(theme.Code, theme.uuid)
        if not code_success then
            warn("Failed to save theme code: " .. theme.uuid)
        end

        local themeSummary = makeThemeSummary(theme)
        local allThemeSummaries = self:getThemeSummary()
        table.insert(allThemeSummaries, themeSummary)

        local save_success = self:saveThemeSummary(allThemeSummaries)
        if not save_success then
            warn("Failed to save theme summary: " .. theme.uuid)
        end
    end

    return success
end


function ThemeStore:getThemeSummary()
    local success, result = DataStoreHelper:_performDataStoreOperationWithRetry(
        ThemeDataStore,
        "GetAsync",
        allThemeSummariesKey,
        nil
    )

    if success then
        return result
    end

    return nil
end

function ThemeStore:saveThemeSummary(themeSummary)
    local success, _ = DataStoreHelper:_performDataStoreOperationWithRetry(
        ThemeDataStore,
        "SetAsync",
        allThemeSummariesKey,
        themeSummary
    )

    if not success then
        warn("Failed to save theme summary: " .. themeSummary.uuid)
    end

    return success
end

function ThemeStore:getThemeByCode(code: string): Theme?
    local result = ThemeCodeStore:getThemeUUID(code)
    if result then
        return self:GetTheme(result)
    end
    return nil
end

function ThemeStore:newTheme(
    name: string, 
    description: string, 
    gradingPrompt: string, 
    duration: number, 
    createdBy: string,
    difficulty: string
): Theme
    local theme = {
        Name = name,
        Description = description,
        GradingPrompt = gradingPrompt,
        Difficulty = difficulty,
        Duration = duration,
        CreatedBy = createdBy,
        uuid = HttpService:GenerateGUID(false),
        CreatedAt = os.time(),
        TotalPlayCount = 0,
        Likes = 0,
    }

    local code: string = self:getUniqueCode(theme.uuid)

    theme.Code = code

    return theme
end

return ThemeStore
