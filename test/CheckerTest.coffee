expect = require('expect.js');

Enum = require('../modules/unbind/Enum')
checker = require('../modules/unbind/Checker');


describe 'Chekers Tests', ->

	it 'should return true for is string', ->
		expect(checker.is.string("hello")).to.be.ok()
		expect(checker.not.string("hello")).to.not.be.ok()

		try
			checker.assert.not.string("hello")
			expect.fail()


	it 'should protect a function with type checks', ->
		called = false

		myLameFunction = (string, number) ->
			called = true
			expect(typeof string).to.be("string")
			expect(typeof number).to.be("number")

		protectedFunction = checker.protect(undefined, "string", "number", myLameFunction)
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
		expect(checker.is({}, {})).to.be.ok()
		expect(checker.is(IPerson, Person)).to.be.ok()

		# anonymous spec
		expect(checker.is({happy: "boolean"}, Person)).to.be.ok();
		expect(checker.is({sad: "boolean"}, Person)).not.to.be.ok();
		expect(checker.is({sad: "string"}, Person)).not.to.be.ok();

		# asserts
		try
			checker.not({happy: "boolean"}, Person)
			expect.fail()


	it 'should be possible to use custom types in function guards', ->
		called = false

		showPerson = (person) ->
			called = true
			expect(person.name).to.be("Ben")
			expect(person.age).to.be(27)

		showPerson = checker.protect(undefined, IPerson, showPerson)
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

		post = checker.protect("string", {to: 'string', from: 'string' }, _post)
		post({to: "Mom", from: "Bobby"})
		expect(called).to.be.ok()

		try
			post({to: "Santa Claus"})
			expect.fail()


	it 'should guard against invalid return values', ->
		called = false

		func = checker.protect('string', () ->
			called = true
			return 1234
		)

		try
			func()
			expect.fail()

		expect(called).to.be.ok()


	it 'should be possible to specify return types in function guards', ->
		called = false

		func = checker.protect('string', {firstName:"", lastName:""}, (person) ->
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

	it 'should be possible to create enums', ->
		expect(Country.USA?.value).to.be("USA")
		expect(Country.Denmark).to.be(undefined)


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

		expect(checker.is(PersonSpec, person1)).to.be.ok()
		expect(checker.not(PersonSpec, person1)).to.not.be.ok()
		expect(checker.is(PersonSpec, person2)).to.not.be.ok()
		expect(checker.is(PersonSpec, person3)).to.not.be.ok()
		expect(checker.is(PersonSpec, person4)).to.not.be.ok()


	it 'should work for regular object parameters', ->
		called = false

		func = (obj) ->
			called = true
			expect(obj.yes).to.be(true)

		pFunc = checker.protect(undefined, "object", func)
		pFunc({yes:yes})
		expect(called).to.be.ok()

		called = false
		pFunc = checker.protect(undefined, {}, func)
		pFunc({yes:yes})
		expect(called).to.be.ok()


	it 'should provide support for basic primitives', ->
		methods = ["null", "undefined", "number", "string", "boolean", "array", "function", "regex", "regEx"]

		test = (value, expected) ->
			for method in methods

				if method is expected
					expect(checker.is[method](value)).to.be.ok()
					expect(checker.not[method](value)).to.not.be.ok()
				else
					expect(checker.not[method](value)).to.be.ok()
					expect(checker.is[method](value)).to.not.be.ok()

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
		pFunc = checker.protect("", "", 0, func)

		try
			pFunc(1, 2)
			expect.fail()


		# with application
		applied = checker.apply("", "", 0, func)("str")
		result = applied(4)
		expect(result).to.be("str -- 4")

		try
			applied(true)
			expect.fail()




## TODO enum for primitives?