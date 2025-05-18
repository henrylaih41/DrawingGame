local ServerScriptService = game:GetService("ServerScriptService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- Require the TestEZ module (inserted into ServerScriptService)
local TestEZ = require(ReplicatedStorage.Modules.TestEZ)

local testsFolder = ServerScriptService:WaitForChild("tests")
TestEZ.TestBootstrap:run({ testsFolder })