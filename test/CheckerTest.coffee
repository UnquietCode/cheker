Enum = require('../modules/unbind/Enum')
checker = require('../modules/unbind/Checker');


#checker.is.string("hello")
#checker.assert.not.string("hello")


myLameFunction = (string, number) ->
	console.log("the string parameter is '#{string}'")
	console.log("the number parameter is '#{number}'")


protectedFunction = checker.protect(myLameFunction, "string", "number")

protectedFunction("1", 2)


#IEvent = {
#
#}




#return






IPerson = {
	name: "string"
	age: 0
	alive: "boolean"
}




Person = {
	name: "Ben"
	age: 27
	alive: 1
	happy: false
}

console.log checker.not(IPerson, Person)
checker.assert.not(IPerson, Person)

return


###




tests = [1, 2.0, "3", true, null, undefined, () -> ""]

for test in tests
	console.log("test value is '#{test}'")
	console.log checker.is.null(test)
	console.log checker.is.undefined(test)
	console.log checker.is.number(test)
	console.log checker.is.string(test)
	console.log checker.is.boolean(test)
	console.log checker.is.object(test)
	console.log checker.is.array(test)
	console.log checker.is.function(test)
	console.log checker.is.regEx(test)
	console.log("\n\n")

###

