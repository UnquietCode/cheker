Enum = require('./Enum')

interfaceHelper = (spec, object, assert) ->
	assert_is.object(spec)
	assert_is.object(object)

	for k,v of spec

		# check that the object has the property at all
		if not object[k]
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

		else
			expectedType = vType


		# check that the object's property type matches
		actualType = if object[k] == null then "null" else typeof object[k]

		if actualType != expectedType
			if assert
				throw new Error("Object does not conform to spec. Property '#{k}' should be of type #{expectedType}.")
			else
				return false


	return true




trueFalseHelper = (match, assert, cb) ->

	typeEquals = (object, type) ->
		actual = (typeof object).toLowerCase()
		equals = actual is type
		retval = if match then equals else not equals
		if cb then cb(retval, type, actual) else return retval


	func = (spec, object) ->
		interfaceHelper(spec, object, assert)

	func.null = (test) ->
			equals = test == null
			retval = if match then equals else not equals
			actual = if equals then "null" else (typeof object).toLowerCase()
			if cb then cb(retval, "null", actual) else return retval

	func.undefined = (test) -> typeEquals(test, 'undefined')
	func.number = (test) -> typeEquals(test, 'number')
	func.string = (test) -> typeEquals(test, 'string')
	func.boolean = (test) -> typeEquals(test, 'boolean')
	func.object = (test) -> typeEquals(test, 'object')
	func.array = (test) -> typeEquals(test, 'array')
	func.function = (test) -> typeEquals(test, 'function')
	func.regex = (test) -> typeEquals(test, 'regexp')
	func.regEx = (test) -> typeEquals(test, 'regexp')

	return func

assertHelper = (match) -> (result, expected, actual) ->
	if not result
		expectedStr = if match then "expected" else "expected anything but"
		throw new Error("type mismatch: #{expectedStr} '#{expected}', but was '#{actual}'")


protectHelperCallback = (types) -> (result, expected, actual) ->
	if not result
		throw new Error("function signature mismatch: expected [#{types}]")


_is = trueFalseHelper(true, false)
_not = trueFalseHelper(false, false)
assert_is = trueFalseHelper(true, true, assertHelper(true))
assert_not = trueFalseHelper(false, true, assertHelper(false))


protectHelper = (f, types...) ->
	assert_is.function f

	return (args...) ->
		for i in [0...args.length]

			# ensure that enough types were provided
			if i >= types.length
				throw new Error("too many arguments")

			# confirm that the type matches our expectations
			helper = trueFalseHelper(true, true, protectHelperCallback(types))
			correctType = types[i].toLowerCase()
			helper[correctType](args[i])



module.exports = {
	is: _is
	not: _not

	assert:
		is:	assert_is
		not: assert_not

	protect: protectHelper
}