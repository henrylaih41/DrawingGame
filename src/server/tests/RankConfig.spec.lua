local RankConfig = require(script.Parent.Parent.modules.gameData.RankConfig)

return function()
    describe("RankConfig.getRankForPoints", function()
        it("returns correct rank for points", function()
            local rank = RankConfig.getRankForPoints(10)
            expect(rank.name).to.equal("Beginner")
            rank = RankConfig.getRankForPoints(500)
            expect(rank.name).to.equal("Creative Pro")
            rank = RankConfig.getRankForPoints(2000)
            expect(rank.name).to.equal("Art Grandmaster")
        end)
    end)
end
