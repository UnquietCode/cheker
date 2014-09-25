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

		protectedFunction = checker.protect(myLameFunction, "string", "number")
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
		expect(checker.is(IPerson, Person)).to.be.ok()

		# anonymous spec
		expect(checker.is({happy: "boolean"}, Person)).to.be.ok();
		expect(checker.is({sad: "boolean"}, Person)).not.to.be.ok();
		expect(checker.is({sad: "string"}, Person)).not.to.be.ok();

		# asserts
		try
			checker.not({happy: "boolean"}, Person)
			expect.fail()


	it 'it should be possible to use custom types in function guards', ->
		called = false

		showPerson = (person) ->
			called = true
			expect(person.name).to.be("Ben")
			expect(person.age).to.be(27)

		showPerson = checker.protect(showPerson, IPerson)
		showPerson(Person)
		expect(called).to.be.ok()

		try
			showPerson(25)
			expect.fail()

		try
			showPerson({})
			expect.fail()


	Country = new (class extends Enum
		constructor: () -> super("USA", "Canada")
	)

	it 'it should be possible to create enums', ->
		expect(Country.USA?.value).to.be("USA")
		expect(Country.Denmark).to.be(undefined)


	it 'it should be possible to use enums in specs', ->

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
#		expect(checker.is(PersonSpec, person3)).to.not.be.ok()
#		expect(checker.is(PersonSpec, person4)).to.not.be.ok()








## TODO real tests
## TODO handling of functions with regular object parameters (should work, zero values in the spec
	# "object"
# {}


###


_postal = (obj) ->
	console.log "To: #{obj.to}\nFrom: #{obj.from}"

post = checker.protect(_postal, {to: 'string', from: 'string' })






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
