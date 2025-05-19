local PlayerDataService = require(script.Parent.Parent.modules.PlayerDataService)

local nextUserId = 1
local function createMockPlayer()
    local p = { Name = "Player" .. nextUserId, UserId = nextUserId }
    nextUserId = nextUserId + 1
    return p
end

return function()
    describe("getDifficultyMultiplier", function()
        it("returns correct multiplier", function()
            expect(PlayerDataService.getDifficultyMultiplier("Easy")).to.equal(1)
            expect(PlayerDataService.getDifficultyMultiplier("Medium")).to.equal(2)
            expect(PlayerDataService.getDifficultyMultiplier("Hard")).to.equal(3)
        end)

        it("returns 1 for unknown difficulty", function()
            expect(PlayerDataService.getDifficultyMultiplier("Unknown")).to.equal(1)
        end)
    end)

    describe("savePlayerData", function()
        it("updates state and fires event", function()
            local player = createMockPlayer()
            local fired = false
            local firedPlayer = nil
            local firedData = nil
            local mockEvents = {
                PlayerDataUpdated = {
                    FireClient = function(self, p, data)
                        fired = true
                        firedPlayer = p
                        firedData = data
                    end,
                },
            }
            local mockStates = { PlayerState = { [player] = {} } }

            PlayerDataService._override({ Events = mockEvents, ServerStates = mockStates })

            local data = { coins = 10 }
            PlayerDataService.savePlayerData(player, data)

            expect(mockStates.PlayerState[player].playerData).to.equal(data)
            expect(fired).to.equal(true)
            expect(firedPlayer).to.equal(player)
            expect(firedData).to.equal(data)
        end)
    end)

    describe("getPlayerData", function()
        it("returns cached data", function()
            local player = createMockPlayer()
            local mockStates = { PlayerState = { [player] = { playerData = { foo = "bar" } } } }
            PlayerDataService._override({ ServerStates = mockStates })
            local data = PlayerDataService.getPlayerData(player)
            expect(data.foo).to.equal("bar")
        end)

        it("fetches from store when missing", function()
            local player = createMockPlayer()
            local called = false
            local mockStore = {
                getPlayer = function(self, p)
                    called = true
                    return { foo = "bar" }, nil
                end,
            }
            local mockStates = { PlayerState = { [player] = {} } }
            PlayerDataService._override({ ServerStates = mockStates, PlayerStore = mockStore })
            local data = PlayerDataService.getPlayerData(player)
            expect(called).to.equal(true)
            expect(data.foo).to.equal("bar")
        end)
    end)

    describe("flushPlayerData", function()
        it("saves player data when present", function()
            local player = createMockPlayer()
            local savedPlayer = nil
            local savedData = nil
            local mockStore = {
                savePlayer = function(self, p, data)
                    savedPlayer = p
                    savedData = data
                end,
            }
            local mockStates = { PlayerState = { [player] = { playerData = { foo = 1 } } } }
            PlayerDataService._override({ ServerStates = mockStates, PlayerStore = mockStore })
            PlayerDataService.flushPlayerData(player)
            expect(savedPlayer).to.equal(player)
            expect(savedData.foo).to.equal(1)
        end)
    end)
end
