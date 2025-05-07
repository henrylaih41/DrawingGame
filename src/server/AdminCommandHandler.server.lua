local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = ReplicatedStorage:WaitForChild("Events")
-- Define authorized admin UserIds
local AdminUserIds = {
    [8240890430] = true, -- your user id here
}
local function packValue(userId, playerName, points)
    -- Anything you want to keep for the row can live in here
    return {
        uid   = userId,      -- just in case
        name  = playerName,  -- what you asked for
        points = points,       -- convenient to have the plain score too
        ts    = os.time()    -- optional: when this record was written
    }
end

Events.AdminCommand.OnServerEvent:Connect(function(player, command, args)
    warn("Admin command received", command)
    if not AdminUserIds[player.UserId] then
        warn("Unauthorized attempt by", player.Name)
        return
    end

    if command == "LoadTheme" then
        local ServerScriptService = game:GetService("ServerScriptService")
        local ThemeLoader = require(ServerScriptService.modules.ThemeLoader)
        ThemeLoader:loadThemes()
    elseif command == "UpdateTopPoints" then
        local MemoryStoreService = game:GetService("MemoryStoreService")
        local DataStoreService = game:GetService("DataStoreService")
        local PlayersDataStore = DataStoreService:GetDataStore("Players")
        local topPointsStore = MemoryStoreService:GetSortedMap("TopPointsV2")
        
        local success, pages = pcall(function()
            return PlayersDataStore:ListKeysAsync()
        end)
        
        if success then
            while true do
                local playerKeys = pages:GetCurrentPage()

                for _, keyInfo in ipairs(playerKeys) do                 -- use ipairs for arrays
                    local keyString = keyInfo.KeyName                   -- <- real key

                    -- Expecting keys like "Player_123456789"
                    local playerIdStr = keyString:match("Player_(%d+)")
                    if not playerIdStr then
                        warn("Key not in expected format:", keyString)
                        -- continue
                    end

                    local ok, playerData = pcall(function()
                        return PlayersDataStore:GetAsync(keyString)
                    end)

                    if ok and playerData and playerData.TotalPoints then
                        local points = playerData.TotalPoints

                        warn(playerIdStr, playerData.Name, points)

                        topPointsStore:SetAsync(
                            playerIdStr,                                 -- map key
                            packValue(tonumber(playerIdStr), playerData.Name, points),
                            30 * 24 * 60 * 60,                           -- 30-day expiry
                            points                                       -- sort key / priority
                        )
                    else
                        warn("Failed to fetch data for", keyString)
                    end
                end
                
                if pages.IsFinished then
                    break
                end
                pages:AdvanceToNextPageAsync()
                warn("Waiting 10 seconds")
                task.wait(10)
            end
        else
            warn("Failed to list players from DataStore:", pages)
        end

        warn("Done")
    end
end)