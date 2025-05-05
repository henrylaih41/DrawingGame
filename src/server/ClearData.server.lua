local SORTED_MAPS = { "AllThemesCache"}
local QUEUES      = {}
local HASH_MAPS   = {}

-------------------------------------------------------------------
-- INTERNAL CONSTANTS
-------------------------------------------------------------------
local MS             = game:GetService("MemoryStoreService")
local BATCH_SIZE     = 100            -- max items to fetch per call
local YIELD_SECONDS  = 0.10           -- small pause between batches
local MAX_RETRIES    = 5              -- retry on transient InternalError

-------------------------------------------------------------------
-- HELPER: safe MemoryStore call with exponential back-off
-------------------------------------------------------------------
local function retry(max, fn, ...)
    local args = { ... }
    for attempt = 1, max do
        local ok, result = pcall(fn, table.unpack(args))
        if ok then
            return result
        end
        local waitTime = 0.05 * 2 ^ (attempt - 1)          -- 0.05 → 0.1 → 0.2 …
        task.wait(waitTime)
    end
    error(("MemoryStore call failed %d× in a row"):format(max))
end


local function clear()
    -------------------------------------------------------------------
    -- 1️⃣  CLEAR SORTED MAPS
    -------------------------------------------------------------------
    for _, name in ipairs(SORTED_MAPS) do
        local map = MS:GetSortedMap(name)
        while true do
            -- grab up to BATCH_SIZE items (lowest sort key first)
            local page = retry(MAX_RETRIES, map.GetRangeAsync, map,
                            Enum.SortDirection.Ascending, BATCH_SIZE)

            if #page == 0 then break end           -- map is empty

            for _, entry in ipairs(page) do
                retry(MAX_RETRIES, map.RemoveAsync, map, entry.key)
            end
            task.wait(YIELD_SECONDS)
        end
        print(("✔ SortedMap '%s' cleared"):format(name))
    end

    -------------------------------------------------------------------
    -- 2️⃣  CLEAR QUEUES
    -------------------------------------------------------------------
    for _, name in ipairs(QUEUES) do
        local queue = MS:GetQueue(name)
        while true do
            -- Peek-and-remove up to BATCH_SIZE items (0 s wait so it’s non-blocking)
            local batch = retry(MAX_RETRIES, queue.ReadAsync, queue, BATCH_SIZE, 0)
            if #batch == 0 then break end

            -- Remove each reservation we just consumed
            for _, item in ipairs(batch) do
                retry(MAX_RETRIES, queue.RemoveAsync, queue, item.Id)
            end
            task.wait(YIELD_SECONDS)
        end
        print(("✔ Queue '%s' cleared"):format(name))
    end

    -------------------------------------------------------------------
    -- 3️⃣  CLEAR HASH MAPS
    -------------------------------------------------------------------
    for _, name in ipairs(HASH_MAPS) do
        local hmap   = MS:GetHashMap(name)
        local cursor = nil                       -- nil = first page
        repeat
            local page = retry(MAX_RETRIES, hmap.ListItemsAsync, hmap, cursor, BATCH_SIZE)
            for _, item in ipairs(page.Items) do
                retry(MAX_RETRIES, hmap.RemoveAsync, hmap, item.Key)
            end
            cursor = page.Cursor                 -- nil when no more pages
            task.wait(YIELD_SECONDS)
        until not cursor
        print(("✔ HashMap '%s' cleared"):format(name))
    end

    print("🎉  All requested MemoryStore structures are now empty.")
end


local RunService = game:GetService("RunService")
local IS_STUDIO = RunService:IsStudio()   -- true in **any** Studio play/run test

-- Safe guard to prevent accidental clearing of data in production.
if IS_STUDIO then
    -- clear()
end
