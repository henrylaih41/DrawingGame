local SchemaValidator = require(script.Parent.Parent.modules.SchemaValidator)

return function()
    describe("SchemaValidator", function()
        it("validates a simple schema successfully", function()
            local schema = SchemaValidator.createSchema({
                name = {required = true, type = "string"},
                age = {required = true, type = "number"}
            })
            local result, err = schema:validate({name = "Alice", age = 30})
            expect(result).to.equal(true)
            expect(err).to.equal("")
        end)

        it("fails validation when required field missing", function()
            local schema = SchemaValidator.createSchema({
                name = {required = true, type = "string"}
            })
            local result, err = schema:validate({})
            expect(result).to.equal(false)
            expect(err).to.equal("name is required but missing")
        end)

        it("fails validation on wrong field type", function()
            local schema = SchemaValidator.createSchema({
                count = {required = true, type = "number"}
            })
            local result, err = schema:validate({count = "five"})
            expect(result).to.equal(false)
            expect(err).to.equal("count is string but must be a number")
        end)
    end)
end
