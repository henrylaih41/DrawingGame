local DisplayCanvasSelector = require(script.Parent.Parent.modules.DisplayCanvasSelector)
local CanvasDraw = require(game:GetService("ReplicatedStorage").Modules.Canvas.CanvasDraw)

return function()
    describe("DisplayCanvasSelector.selectRandomDrawing", function()
        it("avoids returning duplicate drawings", function()
            -- Stub the decompression to avoid dealing with binary data in tests
            CanvasDraw.DecompressImageDataCustom = function(data)
                return data
            end
            local topScores = {
                {key = 1, value = {uid = 1}},
                {key = 2, value = {uid = 2}},
            }

            local drawingsByUser = {
                ["1"] = { {uuid = "a", imageData = "img1", theme = "t", playerId = 1} },
                ["2"] = { {uuid = "b", imageData = "img2", theme = "t", playerId = 2} },
            }

            local function fetch(uid)
                return drawingsByUser[uid]
            end

            local used = {}
            local d1 = DisplayCanvasSelector.selectRandomDrawing(topScores, fetch, used, 3)
            expect(d1).to.be.ok()
            local d2 = DisplayCanvasSelector.selectRandomDrawing(topScores, fetch, used, 3)
            expect(d2).to.be.ok()
            expect(d1.drawingId).never.to.equal(d2.drawingId)
        end)
    end)
end
