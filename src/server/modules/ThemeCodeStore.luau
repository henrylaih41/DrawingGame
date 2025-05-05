local DataStoreService = game:GetService("DataStoreService")
local ServerScriptService = game:GetService("ServerScriptService")
local DataStoreHelper = require(ServerScriptService.modules.DataStoreHelper)
local ThemeCodeStore = {}
local ThemeCodeDataStore = DataStoreService:GetDataStore("ThemeCodes")

function ThemeCodeStore:saveThemeCode(code: string, theme_uuid: string)
    local success, _ = DataStoreHelper:_performDataStoreOperationWithRetry(
        ThemeCodeDataStore,
        "SetAsync",
        "ThemeCode_" .. code,
        theme_uuid,
        true
    )   

    return success
end

-- Add Memory cache if needed.
function ThemeCodeStore:getThemeUUID(code: string): string?
    local success, result = DataStoreHelper:_performDataStoreOperationWithRetry(
        ThemeCodeDataStore,
        "GetAsync",
        "ThemeCode_" .. code,
        nil,
        true
    )

    if success then
        return result
    end

    return nil
end

function ThemeCodeStore:checkCodeNotExists(code: string): boolean
    local success, result = DataStoreHelper:_performDataStoreOperationWithRetry(
        ThemeCodeDataStore,
        "GetAsync",
        "ThemeCode_" .. code,
        nil,
        true
    )

    return success and result == nil
end

return ThemeCodeStore
