local CanvasDraw = require(game:GetService("ReplicatedStorage").Modules.Canvas.CanvasDraw)
local DisplayCanvasSelector = {}

--- Selects a random drawing from the provided top scores while avoiding duplicates.
-- @param topScores table table of leaderboard entries
-- @param fetchTopPlays function function(uid) -> table of drawings
-- @param usedDrawingIds table set of drawing UUIDs already selected
-- @param maxAttempts number maximum attempts to find a unique drawing
-- @return table|nil drawing data table or nil if not found
function DisplayCanvasSelector.selectRandomDrawing(topScores, fetchTopPlays, usedDrawingIds, maxAttempts)
    assert(topScores, "Missing topScores")
    assert(fetchTopPlays, "Missing fetchTopPlays function")
    assert(usedDrawingIds, "Missing usedDrawingIds table")
    assert(maxAttempts, "Missing maxAttempts")

    for _ = 1, maxAttempts do
        local entry = topScores[math.random(1, #topScores)]
        if entry then
            local uid = tostring(entry.key or entry.value.uid)
            local topPlays = fetchTopPlays(uid)
            if topPlays and #topPlays > 0 then
                local topPlay = topPlays[math.random(1, #topPlays)]
                if not usedDrawingIds[topPlay.uuid] then
                    usedDrawingIds[topPlay.uuid] = true
                    return {
                        imageData = CanvasDraw.DecompressImageDataCustom(topPlay.imageData),
                        themeName = topPlay.theme,
                        playerId = topPlay.playerId,
                        drawingId = topPlay.uuid,
                    }
                end
            end
        end
    end

    warn("SelectRandomDrawing: No drawing found")
    return nil
end

return DisplayCanvasSelector
