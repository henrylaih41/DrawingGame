local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = ReplicatedStorage:WaitForChild("Events")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerConfig = require(ServerScriptService.modules.ServerConfig)
-- Define authorized admin UserIds
local AdminUserIds = ServerConfig.ADMIN_USER_IDS
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
    elseif command == "UpdateThemeSummaries" then
        ----------------------------------------------------------------------
        --  Scan all themes in the Themes datastore, create a theme summary
        --  for each one, and store the list of summaries in the Themes 
        --  datastore under key "all_theme_summaries"
        ----------------------------------------------------------------------
        warn("▶ Scanning all themes and creating summaries...")
        
        local DataStoreService = game:GetService("DataStoreService")
        local ThemesStore = DataStoreService:GetDataStore("Themes")
        
        local totalThemes = 0
        local themeSummaries = {}
        
        -- Scan all themes and create summaries
        local success, pages = pcall(function()
            return ThemesStore:ListKeysAsync()
        end)
        
        if success then
            while true do
                local themeKeys = pages:GetCurrentPage()
                
                if #themeKeys == 0 then
                    break -- No more data
                end
                
                warn("Processing batch of " .. #themeKeys .. " themes")
                
                for _, keyInfo in ipairs(themeKeys) do
                    local keyString = keyInfo.KeyName
                    
                    -- Skip the summary key itself to avoid processing it
                    if keyString ~= "all_theme_summaries" then
                        local ok, theme = pcall(function()
                            return ThemesStore:GetAsync(keyString)
                        end)
                        
                        if ok and theme and typeof(theme) == "table" then
                            -- Create a theme summary
                            local themeSummary = {
                                uuid = theme.uuid,
                                Name = theme.Name,
                                Description = string.sub(theme.Description or "", 1, 300), -- Limit to 300 chars
                                CreatedBy = theme.CreatedBy,
                                TotalPlayCount = theme.TotalPlayCount or 0,
                                CreatedAt = theme.CreatedAt,
                                Duration = theme.Duration,
                                Difficulty = theme.Difficulty,
                                Likes = theme.Likes or 0,
                                Code = theme.Code
                            }
                            
                            table.insert(themeSummaries, themeSummary)
                            totalThemes += 1
                            warn("  • Processed theme: " .. (theme.Name or "Unknown") .. 
                                 " (" .. (theme.uuid or "No UUID") .. ")")
                        else
                            warn("Failed to get theme data for", keyString, "or data is not a table")
                        end
                    end
                    
                    -- Small delay between operations to avoid rate limits
                    task.wait(0.5)
                end
                
                warn("Processed " .. totalThemes .. " themes so far")
                
                if pages.IsFinished then
                    break
                end
                
                pages:AdvanceToNextPageAsync()
                warn("Waiting 0.25 seconds")
                task.wait(0.25)
            end
            
            -- Store the list of theme summaries in the datastore
            if #themeSummaries > 0 then
                local ok, err = pcall(function()
                    ThemesStore:SetAsync("all_theme_summaries", themeSummaries)
                end)
                
                if ok then
                    warn("✔ Successfully stored " .. #themeSummaries .. " theme summaries to Themes datastore")
                else
                    warn("✖ Error storing theme summaries: " .. tostring(err))
                end
            else
                warn("No themes found to summarize")
            end
        else
            warn("Failed to list themes from DataStore:", pages)
        end
        
        warn("UpdateThemeSummaries complete")
    end
end)