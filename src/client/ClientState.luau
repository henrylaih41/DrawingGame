local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConstants = require(ReplicatedStorage.Modules.GameData.GameConstants)

local ClientState = {}
-- Global Variables on the client-side.
ClientState.DrawingCanvas = {}
ClientState.PlayerState = GameConstants.PlayerStateEnum.IDLE

return ClientState
