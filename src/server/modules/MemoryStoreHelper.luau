local MemoryStoreService = game:GetService("MemoryStoreService")

local MemoryStoreHelper = {}

function MemoryStoreHelper:_performMemoryStoreOperationWithRetry(store, operation, key, value, additionalArgs, retry)
    -- Default to retrying if the caller doesn't specify otherwise
    if retry == nil then
        retry = true
    end
    local MAX_RETRIES = 5
    local success, result
    
    for attempt = 1, MAX_RETRIES do
        success, result = pcall(function()
            if operation == "GetAsync" then
                return store:GetAsync(key)
            elseif operation == "SetAsync" then
                local options = additionalArgs or {}
                store:SetAsync(key, value, options.expiration, options.sortKey)
                return true
            elseif operation == "UpdateAsync" then
                local options = additionalArgs or {}
                store:UpdateAsync(key, function(oldValue)
                    -- Allow custom transform function to be passed
                    if type(value) == "function" then
                        return value(oldValue)
                    else
                        return value
                    end
                end, options.expiration)
                return true
            elseif operation == "RemoveAsync" then
                store:RemoveAsync(key)
                return true
            elseif operation == "IncrementAsync" then
                local options = additionalArgs or {}
                local delta = value or 1
                return store:IncrementAsync(key, delta, options.expiration)
            elseif operation == "GetRangeAsync" then
                local options = additionalArgs or {}
                print(options)
                return store:GetRangeAsync(options.direction, options.pageSize, options.exclusiveStartKey)
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

return MemoryStoreHelper