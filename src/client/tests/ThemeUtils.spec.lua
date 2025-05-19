local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ThemeUtils = require(ReplicatedStorage.Modules.Utils.ThemeUtils)

return function()
    describe("ThemeUtils.getTrophyMultiplier", function()
        it("returns correct multiplier", function()
            expect(ThemeUtils.getTrophyMultiplier("Easy")).to.equal(1)
            expect(ThemeUtils.getTrophyMultiplier("Medium")).to.equal(2)
            expect(ThemeUtils.getTrophyMultiplier("Hard")).to.equal(3)
            expect(ThemeUtils.getTrophyMultiplier("Unknown")).to.equal(1)
        end)
    end)

    describe("ThemeUtils.sortThemesByDifficulty", function()
        it("sorts by difficulty then name", function()
            local list = {
                {Name = "B", Difficulty = "Medium"},
                {Name = "A", Difficulty = "Easy"},
                {Name = "C", Difficulty = "Medium"},
            }
            local sorted = ThemeUtils.sortThemesByDifficulty(list)
            expect(sorted[1].Name).to.equal("A")
            expect(sorted[2].Name).to.equal("B")
            expect(sorted[3].Name).to.equal("C")
        end)
    end)

    describe("ThemeUtils.removeDuplicateThemes", function()
        it("removes duplicates based on name and difficulty", function()
            local list = {
                {Name = "A", Difficulty = "Easy"},
                {Name = "A", Difficulty = "Easy"},
                {Name = "B", Difficulty = "Medium"},
            }
            local unique = ThemeUtils.removeDuplicateThemes(list)
            expect(#unique).to.equal(2)
        end)
    end)
end
