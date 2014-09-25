Enum = require('./Enum')
log = (x) -> console.log(x)

equalsInterface = (object, spec, assert) ->
	assert_is.object(spec)
	assert_is.object(object)

	# for every property of the interface
	for k,v of spec
		objectValue = object[k]

		# handle enums by unwrapping them
		if v instanceof Enum
			sameMarker = objectValue.marker != undefined && v.marker == objectValue.marker

			if not sameMarker
				if assert
					throw new Error("Object does not conform to spec. Property '#{k}' should be of the correct Enum type.")
				else return false

		# check that the object has the property at all
		if objectValue == undefined
			throw new Error("Object does not conform to spec. Missing property '#{k}'.")

		# get the value type
		vType = if v == null then "null" else typeof v
		expectedType = null

		# check null first so we don't dereference it
		if vType == "null"
			expectedType = "null"

		else if vType == "string"
			stringType = v.toLowerCase()

			# check for known types
			if stringType in ["null", "undefined", "number", "string", "boolean", "object", "array", "function", "regex"]
				expectedType = stringType

			# everything else is a string
			else
				expectedType = "string"

		# otherwise, use the type of the provided object
		else
			expectedType = vType


		# check that the object's property type matches
		actualType = if objectValue == null then "null" else typeof objectValue

		# handle failure
		if actualType != expectedType

			if assert
				throw new Error("Object does not conform to spec. Property '#{k}' should be of type #{expectedType}.")
			else return false


matcher = (match, assert, cb) ->

	equalsType = (object, type) ->
		actual = (typeof object).toLowerCase()
		equals = actual is type
		retval = if match then equals else not equals
		if cb then cb(retval, type, actual) else return retval


	func = (spec, object) ->
		result = equalsInterface(object, spec, assert)

		if result and !match and assert
			throw new Error("expected object to not match spec")

		return result


	func.null = (test) ->
			equals = test == null
			retval = if match then equals else not equals
			actual = if equals then "null" else (typeof object).toLowerCase()
			if cb then cb(retval, "null", actual) else return retval

	func.undefined = (test) -> equalsType(test, 'undefined')
	func.number = (test) -> equalsType(test, 'number')
	func.string = (test) -> equalsType(test, 'string')
	func.boolean = (test) -> equalsType(test, 'boolean')
	func.object = (test) -> equalsType(test, 'object')
	func.array = (test) -> equalsType(test, 'array')
	func.function = (test) -> equalsType(test, 'function')
	func.regex = (test) -> equalsType(test, 'regexp')
	func.regEx = (test) -> equalsType(test, 'regexp')

	return func

assertHelper = (match) -> (result, expected, actual) ->
	if not result
		expectedStr = if match then "expected" else "expected anything but"
		throw new Error("type mismatch: #{expectedStr} '#{expected}', but was '#{actual}'")


protectHelper = (types) -> (result, expected, actual) ->
	if not result
		throw new Error("function signature mismatch: expected [#{types}]")


_is = matcher(true, false)
_not = matcher(false, false)
assert_is = matcher(true, true, assertHelper(true))
assert_not = matcher(false, true, assertHelper(false))

protect = (f, types...) ->
	assert_is.function f

	# return a function which checks all arguments
	# for consistency
	return (args...) ->
		for i in [0...args.length]

			# ensure that enough types were provided
			if i >= types.length
				throw new Error("too many arguments")

			# confirm that the type matches our expectations
			helper = matcher(true, true, protectHelper(types))
			correctType = types[i].toLowerCase()
			helper[correctType](args[i])


###

  cheker

  	# conditional methods
  	.is
  		.string(test)
  	.not
  		.string(test)

  	# same as conditionals but they will throw
  	# an error instead of returning false
  	.assert
  		.is
  			.string(test)
  		.not
  			.string(test)

  	# guard a function with automatic type checks
  	.protect(function, [types])

###
module.exports = {
	is: _is
	not: _not

	assert:
		is:	assert_is
		not: assert_not

	protect: protect
}