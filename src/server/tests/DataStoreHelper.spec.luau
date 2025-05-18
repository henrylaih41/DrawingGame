local DataStoreHelper = require(script.Parent.Parent.modules.DataStoreHelper)

-- Suppress quota output during tests
function DataStoreHelper:printDataStoreQuota()
    -- no-op
end

return function()
    describe("_performDataStoreOperationWithRetry retry flag", function()
        it("should only attempt once when retry is false", function()
            local attempts = 0

            local mockDataStore = {}
            function mockDataStore:GetAsync(key)
                attempts += 1
                error("failure")
            end

            local success, result = DataStoreHelper:_performDataStoreOperationWithRetry(mockDataStore, "GetAsync", "foo", nil, false)

            expect(attempts).to.equal(1)
            expect(success).to.equal(false)
        end)
    end)
end
