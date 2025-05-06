local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = ReplicatedStorage:WaitForChild("Events")

-- Define authorized admin UserIds
local AdminUserIds = {
    [8240890430] = true, -- your user id here
}

Events.AdminCommand.OnServerEvent:Connect(function(player, command, args)
    if not AdminUserIds[player.UserId] then
        warn("Unauthorized attempt by", player.Name)
        return
    end

    if command == "LoadTheme" then
        local ServerScriptService = game:GetService("ServerScriptService")
        local ThemeLoader = require(ServerScriptService.modules.ThemeLoader)
        ThemeLoader:loadThemes()
    end
end)