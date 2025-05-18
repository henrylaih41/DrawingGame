-- Simple TestEZ bootstrap script
-- Requires TestEZ module to be placed under ServerScriptService.TestEZ

local ServerScriptService = game:GetService("ServerScriptService")
local TestEZ = require(ServerScriptService.TestEZ)

-- Folder containing all server tests
local testsFolder = ServerScriptService:WaitForChild("tests")

-- Run all specs under the tests folder
TestEZ.TestBootstrap:run({ testsFolder })

