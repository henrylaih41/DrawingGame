--!native
-- SchemaValidator.luau
-- A utility module for validating data against schemas

local SchemaValidator = {}

-- Function to create a schema definition
function SchemaValidator.createSchema(definition)
    return {
        definition = definition,
        
        -- Validate a value against the schema
        validate = function(self, value, path)
            path = path or ""
            
            if not path then
                return false, path .. " is missing"
            end
            
            for fieldName, fieldDef in pairs(self.definition) do
                local fieldPath = path ~= "" and (path .. "." .. fieldName) or fieldName
                local fieldValue = value[fieldName]
                
                -- Check required field exists
                if fieldDef.required and fieldValue == nil then
                    return false, fieldPath .. " is required but missing"
                end
                
                if fieldValue ~= nil then
                    -- Check field type
                    if fieldDef.type and type(fieldValue) ~= fieldDef.type then
                        return false, fieldPath .. " is " .. type(fieldValue) .. " but must be a " .. fieldDef.type
                    end
                    
                    -- Check custom validation
                    if fieldDef.validate and not fieldDef.validate(fieldValue) then
                        return false, fieldPath .. " failed validation: " .. (fieldDef.errorMessage or "invalid value")
                    end
                    
                    -- Validate nested schema if provided
                    if fieldDef.schema and type(fieldValue) == "table" then
                        local nestedValid, nestedError = fieldDef.schema:validate(fieldValue, fieldPath)
                        if not nestedValid then
                            return false, nestedError
                        end
                    end
                end
            end
            
            return true, "" 
        end
    }
end

return SchemaValidator 