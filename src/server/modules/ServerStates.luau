local ServerStates = {}

-- Constants

-- Variables shared between server scripts
ServerStates.CanvasState = {}
-- This is a table that contains the state of the players in the server.
-- Player is this table is the active players.
ServerStates.PlayerState = {}
-- This is a table that contains the playerId to player map.
ServerStates.PlayerIdToPlayerMap = {}
-- This table holds the drawings shown on display canvases. Each canvas
-- instance maps to data that is sent to clients when they join.
ServerStates.DisplayCanvasDrawings = {}

-- This is a flag that is set to true when the server has finished populating
-- the display canvas drawings.
ServerStates.ServerDisplayImageReady = false

return ServerStates

