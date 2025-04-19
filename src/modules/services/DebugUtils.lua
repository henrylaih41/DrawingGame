-- DebugUtils.lua
-- A simple module for enhanced debugging output.

local DebugUtils = {}

-- Configuration
DebugUtils.IsEnabled = true -- Set to false to disable all debug prints from this module

--- Converts a value to a readable string representation for debugging.
-- Handles tables by showing key-value pairs (non-recursive).
-- @param value any The value to convert.
-- @return string The string representation.
local function valueToString(value)
	local valueType = typeof(value)

	if valueType == "string" then
		return '"' .. value .. '"' -- Add quotes around strings
	elseif valueType == "table" then
		local parts = {}
		for k, v in pairs(value) do
			-- Recursively call valueToString for keys and values for better representation
			-- Avoid infinite recursion for self-referencing tables (basic check)
			local keyStr = (type(k) == "table" and "{...}" or valueToString(k))
			local valStr
			if v == value then -- Basic self-reference check
				valStr = "{self}"
			else
				valStr = valueToString(v) -- Recursive call for value
			end
			table.insert(parts, keyStr .. " = " .. valStr)
		end
		return "{ " .. table.concat(parts, ", ") .. " }"
	elseif valueType == "Instance" then
		return string.format("<Instance %s '%s'>", value.ClassName, value.Name)
	elseif valueType == "nil" then
		return "nil"
	elseif valueType == "boolean" then
		return tostring(value)
	elseif valueType == "number" then
		return tostring(value)
	elseif valueType == "function" then
		return "<function>"
	elseif valueType == "userdata" then
		return "<userdata>"
	elseif valueType == "thread" then
		return "<thread>"
	else
		-- Fallback for other types
		return tostring(value)
	end
end

--- Prints debug messages to the console if debugging is enabled.
-- Handles multiple arguments of different types.
-- @param ... any Variable number of arguments to print.
function DebugUtils.print(prefix, ...)
	if not DebugUtils.IsEnabled then
		return
	end

	local args = {...}
	local outputParts = {}

	for i = 1, #args do
		table.insert(outputParts, valueToString(args[i]))
	end

	print(prefix .. table.concat(outputParts, " "))
end

return DebugUtils 