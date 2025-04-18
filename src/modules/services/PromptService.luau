-- PromptService.luau
-- Module for managing and retrieving predefined prompts

local PromptService = {}

-- Private storage for prompts
-- Keys should be descriptive strings.
local prompts = {
	-- Example Prompts (Replace or add as needed)
	BASIC_PROMPT = "Analyze the submitted drawing based on the theme provided.",
}

--[[
	Retrieves a prompt string based on the provided key, optionally appending theme information.

	@param key The string key identifying the desired prompt.
	@param theme? string An optional theme string to append to the prompt.
	@return The prompt string associated with the key, potentially modified with theme information.
	@throws Asserts false if the key is not provided, not a string, or not found in the prompts table.
	@throws Asserts false if the theme is provided but is not a string.
]]
function PromptService:getPrompt(key, theme)
	assert(key, "PromptService:getPrompt requires a key parameter.")
	assert(typeof(key) == "string", "PromptService:getPrompt key parameter must be a string.")

	local prompt = prompts[key]

	if not prompt then
		warn("PromptService: Prompt key not found - '" .. tostring(key) .. "'")
		assert(false, "PromptService: Prompt key not found: " .. tostring(key))
	end

	-- Check if theme is provided and is a string
	if theme then
		assert(typeof(theme) == "string", "PromptService:getPrompt theme parameter must be a string if provided.")
		-- Append the theme information to the prompt
		prompt = prompt .. " The theme is " .. theme .. "."
	end

	return prompt
end

return PromptService 