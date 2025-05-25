local DataStoreService = game:GetService("DataStoreService")

local DataStoreHelper = {}

function DataStoreHelper:printDataStoreQuota(operationName)
    assert(operationName, "Missing operationName parameter")

    local quotaName = nil
    if operationName == "SetAsync" then
        quotaName = "SetIncrementAsync"
    else
        quotaName = operationName
    end

    -- Find the matching enum value
    local targetRequestType = nil
    for _, reqType in ipairs(Enum.DataStoreRequestType:GetEnumItems()) do
        if reqType.Name == quotaName then
            targetRequestType = reqType
            break
        end
    end
    
    if not targetRequestType then
        warn("Invalid DataStoreRequestType name: " .. quotaName)
        return
    end
    
    -- Get and print the quota for just this request type
    local remaining = DataStoreService:GetRequestBudgetForRequestType(targetRequestType)
    print("─ DataStore request budget for " .. quotaName .. " ─")
    print(string.format("  %-22s : %.0f requests left", quotaName, remaining))
    print("───────────────────────────────────────────────")
end

function DataStoreHelper:printAllDataStoreQuota()
    print("─ Current DataStore request budget (remaining this minute) ─")
    for _, reqType in ipairs(Enum.DataStoreRequestType:GetEnumItems()) do
        local remaining = DataStoreService:GetRequestBudgetForRequestType(reqType)
        -- remaining is a floating-point number that refills continuously
        print(string.format("  %-22s : %.0f requests left", reqType.Name, remaining))
    end
    print("────────────────────────────────────────────────────────────")
end

-- Private utility function for handling DataStore operations with retry logic
function DataStoreHelper:_performDataStoreOperationWithRetry(dataStore, operation, key, value, retry)
    if retry == nil then
        retry = true
    end
    local MAX_RETRIES = 5
    local success, result
    for attempt = 1, MAX_RETRIES do
        -- Removed self:printDataStoreQuota(operation) to reduce logging overhead
        success, result = pcall(function()
            if operation == "GetAsync" then
                return dataStore:GetAsync(key)
            elseif operation == "SetAsync" then
                dataStore:SetAsync(key, value)
                return true
            else
                error("Unsupported operation: " .. operation)
            end
        end)
        
        if success or not retry then
            break
        else 
            warn(result)
            -- Exponential backoff
            task.wait(1 * 2 ^ (attempt - 1))
        end
    end

    return success, result
end

return DataStoreHelper
