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

                        if points > 5 then
                            warn(playerIdStr, playerData.Name, points)
                            topPointsStore:SetAsync(
                                playerIdStr,                                 -- map key
                                packValue(tonumber(playerIdStr), playerData.Name, points),
                                30 * 24 * 60 * 60,                           -- 30-day expiry
                                points                                       -- sort key / priority
                            )
                        end
                    else
                        warn("Failed to fetch data for", keyString)
                    end
                end
                
                if pages.IsFinished then
                    break
                end
                pages:AdvanceToNextPageAsync()
                warn("Waiting 60 seconds")
                task.wait(100)
            end
        else
            warn("Failed to list players from DataStore:", pages)
        end

        warn("Done")
    elseif command == "TrimTopPoints" then
        ----------------------------------------------------------------------
        --  Prune the TopPointsV2 sorted map so it contains at most 100 rows
        --  – works in-place and is RU-friendly (200 items per page, short wait)
        ----------------------------------------------------------------------
        local KEEP_LIMIT          = 100         -- how many ranks to retain
        local PAGE_SIZE           = 200         -- max allowed by API (docs)
        local VISITS_MAP_NAME     = "TopPointsV2"

        local MemoryStoreService  = game:GetService("MemoryStoreService")
        local visitsMap           = MemoryStoreService:GetSortedMap(VISITS_MAP_NAME)

        local rank                = 0           -- running rank counter
        local exclusiveLowerBound = nil         -- nil = start from very top

        while true do
            -- Pull the next page (highest scores first)
            local ok, entries = pcall(function()
                return visitsMap:GetRangeAsync(
                    Enum.SortDirection.Descending,    -- highest-to-lowest
                    PAGE_SIZE,                        -- up to 200 rows
                    exclusiveLowerBound               -- start *after* this bound
                )
            end)

            warn("Entries: ", entries)

            if not ok then
                warn("Failed to read "..VISITS_MAP_NAME..":", entries)
                break
            end
            if #entries == 0 then  -- reached end of map
                break
            end

            ------------------------------------------------------------------
            -- Step through the page.  Anything beyond KEEP_LIMIT is removed.
            ------------------------------------------------------------------
            for _, row in ipairs(entries) do
                rank += 1
                if rank > KEEP_LIMIT then
                    visitsMap:RemoveAsync(row.key)
                    warn(("Removed %s (rank %d, score %s)"):format(
                        tostring(row.key), rank, tostring(row.sortKey)))
                end
            end

            -- Stop if we fetched the last page
            if #entries < PAGE_SIZE then
                break
            end

            ------------------------------------------------------------------
            -- Set up the next page request: exclusiveLowerBound must be a
            -- *table* with both key and sortKey to avoid duplicates when
            -- several rows share the same score.  See official docs. :contentReference[oaicite:0]{index=0}
            ------------------------------------------------------------------
            local last = entries[#entries]
            exclusiveLowerBound = { key = last.key, sortKey = last.sortKey }

            task.wait(0.25)        -- gentle throttle (≈ 4 RU per second)
        end

        warn("TrimTopPoints complete – kept top "..KEEP_LIMIT.." players")
    end
end)