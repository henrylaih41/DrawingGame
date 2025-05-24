local ServerConfig = {}

-- Backend configuration
ServerConfig.BACKEND_BASE_URL = "https://drawing-backend.vercel.app"
ServerConfig.OPENAI_ENDPOINT = "/api/openai"
ServerConfig.FEEDBACK_ENDPOINT = "/api/feedback"

-- Debug flag for server modules
ServerConfig.DEBUG_ENABLED = true

-- Player defaults
ServerConfig.DEFAULT_MAXIMUM_GALLERY_SIZE = 3
ServerConfig.DEFAULT_DRAWING_TTL_AFTER_PLAYER_LEFT = 60 * 60 * 3 -- 3 hours
ServerConfig.DEFAULT_MAXIMUM_ENERGY = 3
ServerConfig.DEFAULT_MAXIMUM_LIKE_QUOTA = 10
ServerConfig.ENERGY_REFRESH_INTERVAL = 60 * 60 * 12 -- seconds

-- DataStore/MemoryStore tuning
ServerConfig.CACHE_TTL_SECONDS = 30 * 60 -- 30 minutes
ServerConfig.LOCK_TTL_SECONDS = 5
ServerConfig.LOCK_RETRIES = 5
ServerConfig.LOCK_RETRY_DELAY = 0.4

-- ClearData script settings
ServerConfig.CLEAR_DATA = {
    BATCH_SIZE = 100,
    YIELD_SECONDS = 0.10,
    MAX_RETRIES = 5,
}

-- Admin configuration
ServerConfig.ADMIN_USER_IDS = {
    [8240890430] = true,
}

-- Proximity prompt settings
ServerConfig.PROMPT = {
    HOLD_DURATION = 0.5,
    MAX_ACTIVATION_DISTANCE = 5,
    TELEPORT_DISTANCE = 2,
    TELEPORT_HEIGHT = 0,
}

-- Display canvas settings
ServerConfig.DISPLAY_CANVAS = {
    MAX_RANDOM_ATTEMPTS = 5,
    JOIN_DELAY_SECONDS = 5,
    CHOOSE_FROM_TOP_N_PLAYERS = 20,
    POLL_INTERVAL_SECONDS = 0.1,
}

ServerConfig.LIKES = {
    FLUSH_INTERVAL = 1,
}

return ServerConfig
