local RankConfig = {}

-- Rank definition ordered from highest to lowest threshold
RankConfig.Definitions = {
    { threshold = 2081, name = "Legendary Creator", color = Color3.fromRGB(255, 0, 255) },
    { threshold = 1581, name = "Art Grandmaster", color = Color3.fromRGB(255, 145, 145) },
    { threshold = 1181, name = "Master Artist", color = Color3.fromRGB(255, 215, 0) },
    { threshold = 881,  name = "Canvas Champion", color = Color3.fromRGB(205, 127, 50) },
    { threshold = 631,  name = "Studio Ace", color = Color3.fromRGB(0, 128, 0) },
    { threshold = 421,  name = "Creative Pro", color = Color3.fromRGB(0, 128, 128) },
    { threshold = 251,  name = "Art Adept", color = Color3.fromRGB(75, 0, 130) },
    { threshold = 121,  name = "Sketch Star", color = Color3.fromRGB(135, 206, 235) },
    { threshold = 31,   name = "Rookie Artist", color = Color3.fromRGB(150, 150, 150) },
    { threshold = 0,    name = "Beginner", color = Color3.fromRGB(200, 200, 200) },
}

--- Returns the rank table for the given points.
-- @param points number The player's point total.
-- @return table? Rank table containing name, color and threshold or nil if points invalid.
function RankConfig.getRankForPoints(points: number)
    if type(points) ~= "number" then
        return nil
    end

    for _, rank in ipairs(RankConfig.Definitions) do
        if points >= rank.threshold then
            return rank
        end
    end

    return nil
end

return RankConfig
