local ServerScriptService = game:GetService("ServerScriptService")

-- Require the TestEZ module (inserted into ServerScriptService)
local TestEZ = require(ServerScriptService:WaitForChild("TestEZ"))

local testsFolder = ServerScriptService:WaitForChild("tests")
TestEZ.TestBootstrap:run({ testsFolder })
