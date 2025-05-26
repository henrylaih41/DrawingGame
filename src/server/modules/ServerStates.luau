local ServerStates = {}

-- Constants

-- Variables shared between server scripts
ServerStates.CanvasState = {}
-- This is a table that contains the state of the players in the server.
-- Player is this table is the active players.
ServerStates.PlayerState = {}
-- This is a table that contains the playerId to player map.
ServerStates.PlayerIdToPlayerMap = {}
-- This is a flag that is set to true when the server has finished populating
-- the display canvas drawings.
ServerStates.ServerDisplayImageReady = false
-- Cache minimal player data for broadcasting to all clients
ServerStates.PlayerDataCache = {}

return ServerStates

