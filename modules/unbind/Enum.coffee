class EnumConstant
	constructor: (@value, @marker) ->

class Enum
	@EnumConstant: EnumConstant
	@marker

	constructor: (fields...) ->
		@marker = this

		fields.forEach (field) =>
			if not typeof field == "string" then throw new Error("fields must be provided as an array of strings")
			fieldName = field.toUpperCase()
			@[fieldName] = new EnumConstant(fieldName, @marker)

module.exports = Enum