class EnumConstant
	constructor: (@value, @marker) ->

class Enum
	@EnumConstant: EnumConstant

	# a unique reference which is used to associate
	# the constants with their parent Enum type
	marker: undefined

	###
  	Takes either an array of strings, or an object whose values
  	are strings. In the first mode, the field name and value are
  	both set to the string. In the second mode, the field name is
  	taken from the object key, and the value from the object value.
	###
	constructor: (fields...) ->
		this.marker = @constructor.marker = @constructor.marker || {}

		# special case of a single object parameter
		if fields.length == 1 and (typeof fields[0]).toLowerCase() == "object"
			for k, v of fields[0]
				field = "#{k}"
				@[field] = new EnumConstant(v, this.marker)

		else
			for field in fields
				if not typeof field == "string" then throw new Error("fields must be provided as an array of strings")
				@[field] = new EnumConstant(field, this.marker)


module.exports = Enum