Enum = require('./Enum')
log = (x) -> console.log(x)


equalsInterface = (object, spec, assert) ->
	assert_is.object(spec)
	assert_is.object(object)

	throwOrReturn = (message) ->
		if assert then throw new Error(message)
		else return false

	# for every property of the interface
	for k,v of spec
		objectValue = object[k]

		# handle enums by unwrapping them
		if v instanceof Enum
			sameMarker = objectValue.marker != undefined && v.marker == objectValue.marker

			if not sameMarker
				return throwOrReturn("Object does not conform to spec. Property '#{k}' should be of the correct Enum type.")

		# check that the object has the property at all
		if objectValue == undefined
			return throwOrReturn("Object does not conform to spec. Missing property '#{k}'.")

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
			return throwOrReturn("Object does not conform to spec. Property '#{k}' should be of type #{expectedType}.")

	#-end

	# all done
	return true


matcher = (match, assert, cb) ->

	equalsType = (object, type) ->
		actual = (typeof object).toLowerCase()
		equals = actual is type
		retval = if match then equals else not equals
		if cb then cb(retval, type, actual) else return retval


	func = (spec, object) ->
		result = equalsInterface(object, spec, assert)
		result = if match then result else !result

		if !result and assert
			matchStr = if match then "match" else "not match"
			throw new Error("expected object to #{matchStr} spec")
		else
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

protect = (rType, types..., f) ->
	assert_is.function f

	# return a function which checks all arguments
	# for consistency
	return (args...) ->

		# check every property in the spec
		for i in [0...args.length]

			# ensure that enough types were provided
			if i >= types.length
				throw new Error("too many arguments")

			# confirm that the type matches our expectations
			helper = matcher(true, true, protectHelper(types))
			type = types[i]
			typeName = (typeof type).toLowerCase()

			if typeName == "string"
				helper[type](args[i])
			else if typeName == "object"
				equalsInterface(args[i], type, true)
			else
				helper[typeName](args[i])


		# everything was ok for arguments, so execute the function
		result = f.apply(this, args)
		rTypeName = (typeof rType).toLowerCase()

		# force return undefined
		if rTypeName == "undefined"
			return undefined

		# check the result type
		if rTypeName == "string"
			matcher(true, true)[rType](result)
		else if rTypeName == "object"
			equalsInterface(result, rType, true)
		else
			matcher(true, true)[rTypeName](result)

		# ok, so return the value
		return result


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
  	.protect([types], function)

###
module.exports = {
	is: _is
	not: _not

	assert:
		is:	assert_is
		not: assert_not

	protect: protect
}