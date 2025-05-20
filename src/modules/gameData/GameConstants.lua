local GameConstants = {}

-- Game state definitions
GameConstants.PlayerStateEnum = {
    -- The player is moving / idle in the workspace
    IDLE = "IDLE",
    -- The player is in the theme list screen.
    THEME_LIST = "THEME_LIST",
    -- The player is drawing on the canvas  
    DRAWING = "DRAWING",
    -- The player is waiting for the drawing to be graded
    GRADING = "GRADING",
    -- The drawing result is being shown to the player.
    RESULTS = "RESULTS",
    COUNTDOWN = "COUNTDOWN",
    VOTING = "VOTING",
}

GameConstants.RENDER_RADIUS = 80
GameConstants.UNRENDER_RADIUS = 100
return GameConstants
