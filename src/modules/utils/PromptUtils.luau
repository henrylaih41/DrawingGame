local PromptUtils = {}

--- Creates and configures a ProximityPrompt instance
-- @param promptName string
-- @param promptActionText string
-- @param promptObjectText string
-- @param promptDuration number
-- @param promptDistance number
-- @param promptKeyboardKeyCode Enum.KeyCode
-- @return ProximityPrompt
function PromptUtils.createPrompt(promptName: string, promptActionText: string, promptObjectText: string, promptDuration: number, promptDistance: number, promptKeyboardKeyCode: Enum.KeyCode)
    local prompt = Instance.new("ProximityPrompt")
    prompt.RequiresLineOfSight = false
    prompt.Name = promptName
    prompt.ActionText = promptActionText
    prompt.ObjectText = promptObjectText
    prompt.HoldDuration = promptDuration
    prompt.MaxActivationDistance = promptDistance
    prompt.KeyboardKeyCode = promptKeyboardKeyCode
    return prompt
end

return PromptUtils
