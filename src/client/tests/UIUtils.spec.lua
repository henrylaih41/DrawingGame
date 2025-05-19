local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIUtils = require(ReplicatedStorage.Modules.Utils.UIUtils)

return function()
    describe("UIUtils.updatePageLabel", function()
        it("updates label text with page information", function()
            local label = Instance.new("TextLabel")
            UIUtils.updatePageLabel(label, 2, 5)
            expect(label.Text).to.equal("2 / 5")
            label:Destroy()
        end)
    end)
end
