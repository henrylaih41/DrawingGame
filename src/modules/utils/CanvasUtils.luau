local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Modules.GameData.GameConfig)

local CanvasUtils = {}

--- Waits until the canvas entry in the client state is initialized.
-- @param clientState table The client state containing DrawingCanvas table.
-- @param canvas Instance The canvas model.
-- @param timeout number? Optional timeout in seconds.
-- @return table? The initialized canvas data or nil on timeout.
function CanvasUtils.waitForCanvasInit(clientState, canvas: Instance, timeout: number?)
    timeout = timeout or GameConfig.CANVAS_INIT_TIMEOUT
    local start = os.clock()
    while os.clock() - start < timeout do
        local data = clientState.DrawingCanvas[canvas]
        if data ~= nil then
            return data
        end
        task.wait(0.1)
    end
    return nil
end

return CanvasUtils
