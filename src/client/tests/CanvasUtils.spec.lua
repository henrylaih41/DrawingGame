local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CanvasUtils = require(ReplicatedStorage.Modules.Utils.CanvasUtils)

return function()
    describe("CanvasUtils.waitForCanvasInit", function()
        it("returns nil when canvas is not initialized in time", function()
            local state = { DrawingCanvas = {} }
            local canvas = Instance.new("Model")
            local start = os.clock()
            local result = CanvasUtils.waitForCanvasInit(state, canvas, 0.1)
            expect(result).to.equal(nil)
            expect(os.clock() - start).to.be.at.least(0.1)
            canvas:Destroy()
        end)

        it("returns data once the canvas is initialized", function()
            local state = { DrawingCanvas = {} }
            local canvas = Instance.new("Model")
            task.delay(0.1, function()
                state.DrawingCanvas[canvas] = {foo = true}
            end)
            local result = CanvasUtils.waitForCanvasInit(state, canvas, 1)
            expect(result).to.be.ok()
            expect(result.foo).to.equal(true)
            canvas:Destroy()
        end)
    end)
end

