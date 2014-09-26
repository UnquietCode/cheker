Enum = require('./Enum')
Primitives = require('./Primitives')
log = (x) -> console.log(x)


equalsInterface = (object, spec, assert) ->
	assert_is.object(spec)
	assert_is.object(object)

	throwOrReturn = (message) ->
		if assert then throw new Error("Object does not conform to spec. #{message}")
		else return false

	# normalize the spec
	spec = translateSpec(spec)

	# for every property of the interface
	for k,v of spec
		objectValue = object[k]

		# check that the object has the property at all
		if objectValue == undefined
			return throwOrReturn("Missing property '#{k}'.")

		# handle enums by unwrapping them, and ensuring
		# they are the same type
		if v instanceof Enum
			sameMarker = objectValue.marker != undefined && v.marker != undefined && v.marker == objectValue.marker

			if not sameMarker
				return throwOrReturn("Property '#{k}' should be of the correct Enum type.")


		# handle custom function declarations by checking
		# that the value is a protected function
		else if v instanceof Primitives.Function.Signature

			# handle nulls
			if objectValue == null
				return throwOrReturn("Property '#{k}' expects a function, but the value was null.");

			signature = objectValue.___chekerSignature

			# handle plain old functions with a warning
			if not signature
				return throwOrReturn("Property '#{k}' is not a protected function.");
				#console.warn("Unable to verify property. Property '#{k}' is not a protected function.")

			# handle cheker functions by looking at the signature and comparing
			badSignature = -> return throwOrReturn("Property '#{k}' should be a function with signature '#{signature.toString()}'")

			# compare return type
			return badSignature() unless compareTypes(signature.rType, v.rType)

			# compare argument types
			for argType,i in signature.types
				return badSignature() unless compareTypes(argType, v.types[i])

			#-end loop

		# else translate the type
		else
			expectedType = translateType(v)
			actualType = translateType(objectValue)

			# handle failure
			if actualType != expectedType
				return throwOrReturn("Property '#{k}' should be of type #{expectedType}.")

	#-end loop

	# all done, and every property was ok
	return true


# TODO
compareTypes = (t1, t2) -> compareTypes(t1, t2, {})

compareTypes = (t1, t2, seen) ->

	# check every property
	if typeOf(t1) == "object" and typeOf(t2) == "object"

		for k1,v1 of t1
			v2 = t2[k1]

			# missing property
			return false unless v2

			# recurse
			return false unless compareTypes(v1, v2, seen)

		# all properties check out
		return true

	# translate and compare
	else
		translated1 = translateType(t1)
		translated2 = translateType(t2)
		return translated1 == translated2


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
		realTypes = getTypeString(type) for type, i in types
		throw new Error("function signature mismatch: expected [#{realTypes}]")


_is = matcher(true, false)
_not = matcher(false, false)
assert_is = matcher(true, true, assertHelper(true))
assert_not = matcher(false, true, assertHelper(false))

# translate a single type
translateType = (obj) -> translateSpec({ $: obj })["$"]

###
	Translate a spec object into one which is normalized
  for the internal methods.
###
translateSpec = (spec) ->
	assert_is.object(spec)
	newSpec = {}

	for k,v of spec
		k = "#{k}" # normalize

		# typeof null is not "null"
		if v == null
			newSpec[k] = Primitives.Null

		else newSpec[k] = switch typeOf(v)
			when "undefined" then Primitives.Undefined
			when "number" then Primitives.Number
			when "boolean" then Primitives.Boolean
			when "array" then Primitives.Array
			when "function" then Primitives.Function
			when "regex" then Primitives.RegEx

			# objects mean we should use the actual instance
			when "object" then v

			# if it is a string, try to figure out
			# which primitive it is talking about
			when "string"
				v = v.toLowerCase().trim() # normalize

				# maybe the string of another primitive?
				if v in ["null", "undefined", "number", "string", "boolean", "object", "array", "function", "regex"]
					v = v[0].toUpperCase()+v[1..]
					Primitives[v]

				# assume it is just an example string
				else
					Primitives.String

			# fail
			else throw new Error("unknown type!")

	#- end loop

	return newSpec;


typeOf = (obj) -> (typeof obj).toLowerCase()

getTypeString = (type) ->
	typeName = typeOf(type)

	# check for known string types
	if typeName == "string"
		stringType = type.toLowerCase()

		if stringType in ["null", "undefined", "number", "string", "boolean", "object", "array", "function", "regex"]
			return stringType


	return typeName


# confirm that the type matches our expectations
matchArgumentType = (arg, type, types) ->
	helper = matcher(true, true, protectHelper(types))
	return matchType(type, arg, helper)

matchType = (type, arg, helper) ->
	expectedType = translateType(type)

	if typeOf(type) == "object" and typeOf(arg) == "object"
		equalsInterface(arg, type, true)
	else
		helper[expectedType.value](arg)



protect = (rType, types..., f) ->
	assert_is.function f

	# return a function which checks all arguments
	# for consistency
	newFunction = (args...) ->

		# check every property in the spec
		for i in [0...args.length]

			# ensure that enough types were provided
			if i >= types.length
				throw new Error("too many arguments")

			# confirm that the type matches our expectations
			matchArgumentType(args[i], types[i], types)


		# everything was ok for arguments, so execute the function
		result = f.apply(this, args)
		rTypeName = getTypeString(rType)

		# force return undefined
		if rTypeName == "undefined"
			return undefined

		# check the result type
		if rTypeName == "object"
			equalsInterface(result, rType, true)
		else
			matcher(true, true)[rTypeName](result)

		# ok, so return the value
		return result


	# mark the function and return it
	newFunction.___chekerSignature = new Primitives.Function.Signature(rType, types...)
	return newFunction

apply = (rType, types..., originalFunction) ->

	# return a function which checks arguments once,
	# then returns a pre-applied function
	return (appliedArgs...) ->

		# get the relevant portion of the types
		appliedTypes = types[0...appliedArgs.length]

		# check them
		for type, i in appliedTypes
			matchArgumentType(appliedArgs[i], type, types)


		# ok, so return an applied protected function
		remainingTypes = types[appliedArgs.length...types.length]

		return protect(rType, remainingTypes..., (args...) ->

			# combine the args
			args = appliedArgs.concat(args)

			# execute the original function
			return originalFunction.apply(this, args)
		)


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
  	.protect(returnType, argumentTypes..., function)

  	# check some arguments, apply them, then check the remaining
  	# arguments as normal with each invocation of the function
  	.apply(returnType, argumentTypes..., function)

###
module.exports = {
	is: _is
	not: _not

	assert:
		is:	assert_is
		not: assert_not

	protect: protect
	apply: apply
}