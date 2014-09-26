expect = require('expect.js');

Enum = require('../modules/cheker/Enum')
Primitives = require('../modules/cheker/Primitives');
cheker = require('../modules/cheker/Checker');

describe 'Enum Tests', ->

	it 'should have the same marker between instances', ->

		# same between instances
		Type1 = new (class extends Enum
			constructor: () -> super("One", "Two", "Three")
		)
		expect(Type1.One.marker).to.be(Type1.Two.marker)


		# different between types
		Type2 = new (class extends Enum
			constructor: () -> super("Alpha", "Beta", "Delta")
		)
		expect(Type1.One.marker).to.not.be(Type2.Alpha.marker)


		# same between multiple instances of the same type
		class Type3 extends Enum
			constructor: () -> super("A", "B", "C")

		Type3A = new Type3()
		Type3B = new Type3()
		expect(Type3A.A.marker).to.be(Type3B.A.marker)



	it 'should be possible to create enums', ->
		Country = new (class extends Enum
			constructor: () -> super("USA", "Canada")
		)
		expect(Country.USA?.value).to.be("USA")
		expect(Country.Denmark).to.be(undefined)



describe 'Cheker Tests', ->

	it 'should return true for is string', ->
		expect(cheker.is.string("hello")).to.be.ok()
		expect(cheker.not.string("hello")).to.not.be.ok()

		try
			cheker.assert.not.string("hello")
			expect.fail()


	it 'should protect a function with type checks', ->
		called = false

		myLameFunction = (string, number) ->
			called = true
			expect(typeof string).to.be("string")
			expect(typeof number).to.be("number")

		protectedFunction = cheker.protect(undefined, "string", "number", myLameFunction)
		protectedFunction("1", 2)
		expect(called).to.be.ok()

		# test failure
		try
			protectedFunction(1, 2)
			expect.fail()

		try
			protectedFunction()
			expect.fail()


	IPerson = {
		name: "string"
		age: 0
		alive: "boolean"
	}

	Person = {
		name: "Ben"
		age: 27
		alive: true
		happy: false
	}

	it 'should support checking of interface specifications', ->
		expect(cheker.is({}, {})).to.be.ok()
		expect(cheker.is(IPerson, Person)).to.be.ok()

		# anonymous spec
		expect(cheker.is({happy: "boolean"}, Person)).to.be.ok()
		expect(cheker.is({sad: "boolean"}, Person)).not.to.be.ok()
		expect(cheker.is({sad: "string"}, Person)).not.to.be.ok()

		# asserts
		try
			cheker.not({happy: "boolean"}, Person)
			expect.fail()


	it 'should be possible to use custom types in function guards', ->
		called = false

		showPerson = (person) ->
			called = true
			expect(person.name).to.be("Ben")
			expect(person.age).to.be(27)

		showPerson = cheker.protect(undefined, IPerson, showPerson)
		showPerson(Person)
		expect(called).to.be.ok()

		try
			showPerson(25)
			expect.fail()

		try
			showPerson({})
			expect.fail()


	it 'should be possible to use anonymous specs in function guards', ->
		called = false

		_post = (obj) ->
			called = true
			expect(typeof obj.to).to.be('string')
			expect(typeof obj.from).to.be('string')
			return "To: #{obj.to}\nFrom: #{obj.from}"

		post = cheker.protect("string", {to: 'string', from: 'string' }, _post)
		post({to: "Mom", from: "Bobby"})
		expect(called).to.be.ok()

		try
			post({to: "Santa Claus"})
			expect.fail()


	it 'should guard against invalid return values', ->
		called = false

		func = cheker.protect('string', () ->
			called = true
			return 1234
		)

		try
			func()
			expect.fail()

		expect(called).to.be.ok()


	it 'should be possible to specify return types in function guards', ->
		called = false

		func = cheker.protect('string', {firstName:"", lastName:""}, (person) ->
			called = true
			return "Hello #{person.firstName} #{person.lastName}!"
		)

		greeting = func({firstName: "Samantha", lastName: "Borges"})
		expect(called).to.be.ok()
		expect(typeof greeting).to.be("string")
		expect(greeting).to.be("Hello Samantha Borges!")



	Country = new (class extends Enum
		constructor: () -> super("USA", "Canada")
	)

	it 'should be possible to use enums in specs', ->

		PersonSpec = {
			name: ""
			country: Country
		}

		person1 = {
			name: "Ted"
			country: Country.USA
		}

		person2 = {
			name: "Tina"
			country: ""
		}

		person3 = {
			name: "Tycho"
			country: 100
		}

		person4 = {
			name: 4
			country: Country.USA
		}

		expect(cheker.is(PersonSpec, person1)).to.be.ok()
		expect(cheker.not(PersonSpec, person1)).to.not.be.ok()
		expect(cheker.is(PersonSpec, person2)).to.not.be.ok()
		expect(cheker.is(PersonSpec, person3)).to.not.be.ok()
		expect(cheker.is(PersonSpec, person4)).to.not.be.ok()


	it 'should work for regular object parameters', ->
		called = false

		func = (obj) ->
			called = true
			expect(obj.yes).to.be(true)

		pFunc = cheker.protect(undefined, "object", func)
		pFunc({yes:yes})
		expect(called).to.be.ok()

		called = false
		pFunc = cheker.protect(undefined, {}, func)
		pFunc({yes:yes})
		expect(called).to.be.ok()


	it 'should provide support for basic primitives', ->
		methods = ["null", "undefined", "number", "string", "boolean", "array", "function", "regex", "regEx"]

		test = (value, expected) ->
			for method in methods

				if method is expected
					expect(cheker.is[method](value)).to.be.ok()
					expect(cheker.not[method](value)).to.not.be.ok()
				else
					expect(cheker.not[method](value)).to.be.ok()
					expect(cheker.is[method](value)).to.not.be.ok()

		test(x[0], x[1]) for x in [
			[1, "number"]
			[2.0, "number"]
			["3", "string"]
			["", "string"]
			[true, "boolean"]
			[null, "null"]
			[undefined, "undefined"]
			[(->), "function"]
		]


	it 'should be possible to guard once, and then apply the arguments', ->
		func = (string, number) -> "#{string} -- #{number}"

		# failing
		pFunc = cheker.protect("", "", 0, func)

		try
			pFunc(1, 2)
			expect.fail()


		# with application
		applied = cheker.apply("", "", 0, func)("str")
		result = applied(4)
		expect(result).to.be("str -- 4")

		try
			applied(true)
			expect.fail()


	it 'should allow for typed function declarations in interface specs', ->

		spec = {
			prop: Primitives.String
			func: Primitives.Function("string", "string", "number")
		}

		good = {
			prop: "something"
			func: cheker.protect("string", "string", "number", (string, number) -> "#{string} -- #{number}")
		}
		expect(cheker.is(spec, good)).to.be.ok()
		expect(cheker.not(spec, good)).to.not.be.ok()


		# wrong signature
		bad1 = {
			prop: "nothing"
			func: cheker.protect("string", "string", "boolean", (string, boolean) -> "#{string} -- #{boolean}")
		}
		expect(cheker.not(spec, bad1)).to.be.ok()
		expect(cheker.is(spec, bad1)).to.not.be.ok()


		# no signature
		bad2 = {
			prop: "nothing"
			func: (string, boolean) -> "#{string} -- #{boolean}"
		}
		expect(cheker.not(spec, bad2)).to.be.ok()
		expect(cheker.is(spec, bad2)).to.not.be.ok()


	it 'should allow for complex objects in the return type (without args) of typed function declarations', ->

		spec = {
			prop: Primitives.String
			func: Primitives.Function({prop: "string"})
		}

		obj = {
			prop: "something"
			func: cheker.protect({prop: "string"}, () -> {prop: 'ello!'})
		}

		expect(cheker.is(spec, obj)).to.be.ok()
		expect(cheker.not(spec, obj)).to.not.be.ok()



	it 'should allow for complex objects in the arguments of typed function declarations', ->

		spec = {
			prop: Primitives.String
			func: Primitives.Function("string", {prop: "string"})
		}


###
	it 'should support varargs'

	it 'should support any object *'

	it 'should allow for varargs in typed function declarations', ->

		spec = {
			prop: Primitives.String
			func: Primitives.Function({prop: "string"}, "*...")
		}

		obj = {
			prop: "something"
			func: cheker.protect({prop: "string"}, (string, number) -> {prop: "#{string} -- #{number}"})
		}

		expect(cheker.is(spec, obj)).to.be.ok()
		expect(cheker.not(spec, obj)).to.not.be.ok()
###


## TODO refector to allow enum prims and function decls

## TODO change protect to 'guard'

# null tests, undefined tests

# "*" any object?