Enum = require('./Enum')
log = (x) -> console.log(x)

UNDEFINED = {}
SIGNATURE_KEY = "___chekerSignature"

Signature = class
	constructor: (@rType, @types...) ->
	toString: -> "#{@rType} -> #{@types}"


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
		expectedType = translateType(v)
		objectValue = object[k]

		# check that the object has the property at all
		if expectedType != UNDEFINED and objectValue == undefined
			return throwOrReturn("Missing property '#{k}'.")


		# handle enums by unwrapping them, and ensuring
		# they are the same type
		if v instanceof Enum
			sameMarker = objectValue.marker != undefined && v.marker != undefined && v.marker == objectValue.marker

			if not sameMarker
				return throwOrReturn("Property '#{k}' should be of the correct Enum type.")


		# handle custom function declarations by checking
		# that the value is a protected function
		else if v instanceof Signature

			# handle nulls
			if objectValue == null
				return throwOrReturn("Property '#{k}' expects a function, but the value was null.");

			signature = objectValue[SIGNATURE_KEY]

			# handle plain old functions with a warning
			if not signature
				return throwOrReturn("Property '#{k}' is not a guarded function.");

			# check that signatures match
			if not compareSignatures(v, signature)
				return throwOrReturn("Property '#{k}' should be a function with signature '#{v.toString()}'")

			#-end loop

		# else translate the type
		else
			actualType = translateValueType(objectValue)

			if typeOf(actualType) == 'object' and typeOf(expectedType) == 'function' and not(actualType instanceof expectedType)
				return throwOrReturn("Property '#{k}' should be the correct instance type.")

			# handle failure
			if expectedType != Object and actualType != expectedType
				return throwOrReturn("Property '#{k}' should be of type #{expectedType}.")

	#-end loop

	# all done, and every property was ok
	return true


compareSignatures = (sig1, sig2) ->

	# TODO helper to check instances?
	if not (sig1 instanceof Signature) or not (sig2 instanceof Signature)
		throw new Error("expected arguments to be signatures")

	# compare return type
	return false unless compareTypes(sig1.rType, sig2.rType)

	# compare argument types
	for argType,i in sig1.types
		return false unless compareTypes(argType, sig2.types[i])

	return true



# TODO seen?
compareTypes = (t1, t2) -> compareTypes(t1, t2, {})

compareTypes = (t1, t2, seen) ->

	# check for signatures
	if t1 instanceof Signature and t2 instanceof Signature
		return compareSignatures(t1, t2)

	# check every property
	else if typeOf(t1) == "object" and typeOf(t2) == "object"

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

	# comparison function
	func = (spec, object) ->

		# check args
		if _not.object(spec) or _not.object(object)
			if assert then throw new Error("only comparisons between a specification and an object are allowed")
			else result = false
		else
			result = equalsInterface(object, spec, assert)

		result = if match then result else !result

		if !result and assert
			matchStr = if match then "match" else "not match"
			throw new Error("expected object to #{matchStr} spec")
		else return result

	equalsType = (object, type) ->
		actual = (typeof object).toLowerCase()
		equals = actual is type
		result = if match then equals else not equals
		cb?(result, type, actual)

		if !result and assert
			throw new Error("expected object to match type '#{getTypeString(type)}")
		else return result

	func.null = (test) ->
			equals = test == null
			result = if match then equals else not equals
			actual = if equals then "null" else (typeof object).toLowerCase()
			cb?(result, "null", actual)

			if !result and assert
				throw new Error("expected object to be null")
			else return result

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
		realTypes = []
		realTypes.push(getTypeString(type)) for type in types
		throw new Error("function signature mismatch: expected [#{realTypes}]")


_is = matcher(true, false)
_not = matcher(false, false)
assert_is = matcher(true, true, assertHelper(true))
assert_not = matcher(false, true, assertHelper(false))


translateValueType = (obj) ->
	if obj == null then return null

	switch typeOf(obj)
		when "number" then Number
		when "undefined" then UNDEFINED
		when "object" then obj
		when "string" then String
		when "boolean" then Boolean
		when "function" then obj
		when "regexp" then RegExp


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
			newSpec[k] = null

		else newSpec[k] = switch typeOf(v)
			when "undefined" then UNDEFINED

			# function should return the actual instance
			when "function" then v

			# objects mean we should use the actual instance
			when "object" then v

			# fail
			else throw new Error("invalid type '#{typeOf(v)}'")

	#- end loop

	return newSpec;


typeOf = (obj) -> (typeof obj).toLowerCase()

getTypeString = (type) ->
	switch type
		when String then "String"
		when Boolean then "Boolean"
		when Object then "Object"
		when Function then "Function"
		when Number then "Number"
		when RegExp then "RegExp"
		else typeOf(type)


# confirm that the type matches our expectations
matchArgumentType = (arg, type, types) ->
	helper = matcher(true, true, protectHelper(types))
	result = matchType(type, arg, helper)

	if not result
		throw new Error("expected '#{arg}' to be of type #{getTypeString(type)}")


matchType = (type, arg, helper) ->
	expectedType = translateType(type)

	# handle null and undefined first
	if expectedType == null then return arg == null
	if expectedType == UNDEFINED then return arg == undefined

	# two objects, compare by spec
	if typeOf(type) == "object" and typeOf(arg) == "object"
		return equalsInterface(arg, type, true)

	# function, compare by type or instance
	else if typeOf(type) == "function"
		argType = typeOf(arg)
		valid = (t) -> type == t or type == Object

		switch argType
			when "string" then return valid(String)
			when "number" then return valid(Number)
			when "boolean" then return valid(Boolean)
			when "regexp" then return valid(RegExp)
			when "function" then return valid(Function)

			when "object" then return arg instanceof type
			else throw new Error("unknown type #{type}")

	# if its the any object, don't worry about it
	else if expectedType is Object
		return true

	# if it is a function signature...
	else if expectedType instanceof Signature and typeOf(arg) == "function" and arg[SIGNATURE_KEY]
		return compareSignatures(expectedType, arg[SIGNATURE_KEY])

	else
		return helper[typeOf(type)](arg)



guard = (rType, types..., f) ->
	assert_is.function f

	# return a function which checks all arguments
	# for consistency
	newFunction = (args...) ->
		newArgs = []

		# check every property in the spec
		for arg, i in args

			# ensure that enough types were provided
			if i >= types.length
				throw new Error("too many arguments")

			type = types[i]
			argument = arg # copy out of the loop

			# transform objects by wrapping their properties in guarded functions
			if typeOf(arg) == "object" and typeOf(type) == "object"
				newThing = {}

				# for every property of the type, if it's a signature, wrap its partner
				for k1,v1 of arg
					v2 = type[k1]
					newThing[k1] = v1

					if typeOf(v1) == "function" and v2 instanceof Signature

						# look for the sig property, means already wrapped
						if not v2[SIGNATURE_KEY]
							newThing[k1] = guard(v2.rType, v2.types..., v1)

				#-- end object loop
				argument = newThing

			#-- end object check

			# wrap functions too
			else if typeOf(arg) == "function" and typeOf(type) == "object"

				# wrap plain functions
				if type instanceof Signature and not arg[SIGNATURE_KEY]
					argument = guard(type.rType, type.types..., arg)

			#-- end function check

			# confirm that the type matches our expectations
			matchArgumentType(argument, type, types)
			newArgs[i] = argument

		# everything was ok for arguments, so execute the function
		result = f.apply(this, newArgs)

		# force return undefined
		expectedReturnType = translateType(rType)

		if expectedReturnType == UNDEFINED
			return undefined

		# check the result type
		matchArgumentType(result, rType, types)

		# ok, so return the value
		return result


	# mark the function and return it
	newFunction[SIGNATURE_KEY] = new Signature(rType, types...)
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

		return guard(rType, remainingTypes..., (args...) ->

			# combine the args
			args = appliedArgs.concat(args)

			# execute the original function
			return originalFunction.apply(this, args)
		)


_extends = (spec1, spec2, assert) ->
	assert_is.object(spec1)
	assert_is.object(spec2)

	for k1,v1 of spec1
		v2 = spec2[k1]

		if v1 != v2
			if assert	throw new Error("Objects do not match. Expected matching property '#{k1}'.")
			else return false

	return true


extend = (obj1, obj2) ->
	assert_is.object(obj1)
	assert_is.object(obj2)
	obj3 = {}

	obj3[key] = value for key,value of obj1
	obj3[key] = value for key,value of obj2
	return obj3


inherits = (func, obj) ->
	assert_is.function(func)
	assert_is.object(obj)

	if not (obj instanceof func)
		throw new Error("expected instance of '#{func}'")


narrow = (objects..., f) ->

	return (args...) ->

		# check for same argument count
		if objects.length != args.length
			throw new Error("incorrect number of arguments")

		# check for validity
		for arg, i in args
			expectedType = objects[i]

			if typeOf(expectedType) == "function"
				inherits(expectedType, arg)
			else
				_extends(expectedType, arg, true)

		# all good
		f(args...)


_Function = (rType, types...) ->
	return new Signature(rType, types...)

Signature = Signature


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
  	.guard(returnType, argumentTypes..., function)

  	# check some arguments, apply them, then check the remaining
  	# arguments as normal with each invocation of the function
  	.apply(returnType, argumentTypes..., function)

  	# ensure that an object extends another object, or that an object
  	# is an instance of a constructor function
  	.narrow(objectOrFunctions..., function)

###
module.exports = {
	is: _is
	not: _not

	assert:
		is:	assert_is
		not: assert_not
		extends: (spec1, spec2) -> _extends(spec1, spec2, true)

	extend: extend
	extends: (spec1, spec2) -> _extends(spec1, spec2, false)

	narrow: narrow
	guard: guard
	apply: apply

	Function: _Function
	Enum: Enum
}