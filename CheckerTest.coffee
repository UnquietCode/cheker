expect = require('expect.js');

Enum = require('./Enum')
cheker = require('./Cheker');

expectFailure = (cb) ->

	try
		cb()
	catch e
		return

	expect().fail()


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

		expectFailure(-> cheker.assert.not.string("hello"))


	it 'should protect a function with type checks', ->
		called = false

		myLameFunction = (string, number) ->
			called = true
			expect(typeof string).to.be("string")
			expect(typeof number).to.be("number")

		protectedFunction = cheker.guard(undefined, String, Number, myLameFunction)
		protectedFunction("1", 2)
		expect(called).to.be.ok()

		# test failure
		expectFailure(-> protectedFunction(1, 2))
		expectFailure(-> protectedFunction())


	IPerson = {
		name: String
		age: Number
		alive: Boolean
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
		expect(cheker.is({happy: Boolean}, Person)).to.be.ok()
		expect(cheker.is({sad: Boolean}, Person)).not.to.be.ok()
		expect(cheker.is({sad: String}, Person)).not.to.be.ok()

		# asserts
		expectFailure(-> cheker.assert.not({happy: Boolean}, Person))


	it 'should be possible to use custom types in function guards', ->
		called = false

		showPerson = (person) ->
			called = true
			expect(person.name).to.be("Ben")
			expect(person.age).to.be(27)

		showPerson = cheker.guard(undefined, IPerson, showPerson)
		showPerson(Person)
		expect(called).to.be.ok()

		expectFailure(-> showPerson(25))
		expectFailure(-> showPerson({}))


	it 'should be possible to use anonymous specs in function guards', ->
		called = false

		_post = (obj) ->
			called = true
			expect(typeof obj.to).to.be('string')
			expect(typeof obj.from).to.be('string')
			return "To: #{obj.to}\nFrom: #{obj.from}"

		post = cheker.guard(String, {to: String, from: String}, _post)
		post({to: "Mom", from: "Bobby"})
		expect(called).to.be.ok()

		expectFailure(-> post({to: "Santa Claus"}))


	it 'should guard against invalid return values', ->
		called = false

		func = cheker.guard(String, () ->
			called = true
			return 1234
		)

		expectFailure(func)
		expect(called).to.be.ok()


	it 'should be possible to specify return types in function guards', ->
		called = false

		func = cheker.guard(String, {firstName:String, lastName:String}, (person) ->
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
			name: String
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

		pFunc = cheker.guard(undefined, Object, func)
		pFunc({yes:yes})
		expect(called).to.be.ok()

		called = false
		pFunc = cheker.guard(undefined, {}, func)
		pFunc({yes:yes})
		expect(called).to.be.ok()


		pFunc = cheker.guard(undefined, Object, (obj) ->
			called = true
			expect((typeof obj).toLowerCase() == "object").to.be(true)
		)

		called = false
		pFunc({})
		expect(called).to.be.ok()

		called = false
		pFunc(new Date())
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
		pFunc = cheker.guard(String, String, Number, func)

		expectFailure(-> pFunc(1, 2))


		# with application
		applied = cheker.apply(String, String, Number, func)("str")
		result = applied(4)
		expect(result).to.be("str -- 4")

		expectFailure(-> applied(true))


	it 'should allow for typed function declarations in interface specs', ->

		spec = {
			prop: String
			func: cheker.Function(String, String, Number)
		}

		good = {
			prop: "something"
			func: cheker.guard(String, String, Number, (string, number) -> "#{string} -- #{number}")
		}
		expect(cheker.is(spec, good)).to.be.ok()


		# wrong signature
		bad1 = {
			prop: "nothing"
			func: cheker.guard(String, String, Boolean, (string, boolean) -> "#{string} -- #{boolean}")
		}
		expect(cheker.not(spec, bad1)).to.be.ok()


		# no signature
		bad2 = {
			prop: "nothing"
			func: (string, boolean) -> "#{string} -- #{boolean}"
		}
		expect(cheker.not(spec, bad2)).to.be.ok()


	it 'should allow for complex objects in the return type (without args) of typed function declarations', ->

		spec = {
			prop: String
			func: cheker.Function({prop: String})
		}

		obj = {
			prop: "something"
			func: cheker.guard({prop: String}, () -> {prop: 'ello!'})
		}

		expect(cheker.is(spec, obj)).to.be.ok()


	it 'should support any object in specs', ->

		spec = {
			prop: Object
		}

		obj = {
			prop: "yup"
		}

		expect(cheker.is(spec, obj)).to.be.ok()

	it 'should fail when returning the wrong type from a guarded function', ->
		func = cheker.guard(Number, () -> return "hello")

		expectFailure(func)


	it 'should block returns from a guarded undefined function', ->
		result = cheker.guard(undefined, () -> return "hello")()
		expect(result).to.be(undefined)

	it 'should allow any return type from a guarded function', ->
		result = cheker.guard(Object, () -> return "hello")()
		expect(result).to.be("hello")


	it 'should work for null and undefined', ->
		expect(cheker.is({a: null}, {a: null, b:""})).to.be.ok()
		expect(cheker.is({a: undefined}, {a: undefined, b:""})).to.be.ok()


	it 'should be able to guard a function with narrowed objects', ->
		parent = {
			one: 1
		}

		child = cheker.extend(parent, {
			two: 2
		})

		narrowed = cheker.narrow(parent, (pType) ->
			return pType.one
		)
		expect(narrowed(child)).to.be(1)

		expectFailure(-> narrowed({ three: 3	}))


	it 'should be able to guard a function with narrowed functions', ->
		class Parent
			one: 1

		class Child extends Parent
			two: 2

		class Nothing
			three: 3


		narrowed = cheker.narrow(Parent, (pType) ->
			return pType.one
		)

		expect(narrowed(new Child())).to.be(1)
		expectFailure(-> narrowed(new Nothing()))



	it 'should consider prototypes when looking at narrowed types', ->
		class A
			one: "1"

		class B extends A
			two: 2


		narrowed = cheker.narrow(new A(), (obj) -> "boop")
		narrowed(new B())


	it 'should fail for invalid interface instance type', ->
		class A
		class B
		spec = { p: A }

		expectFailure(cheker.guard(spec, () -> return { p: new B() }))



	it 'should work as a narrow', ->

		ITask = {
			getData: cheker.Function(Object...)
		}

		IWorker = (TaskType) -> {
			doWork: cheker.Function(undefined, TaskType)
		}


		ICustomTask = cheker.extend(ITask, {
			getName: cheker.Function(String)
		})

		ICustomWorker = cheker.extend(IWorker(ICustomTask), {
			running: Boolean
		})


		class CustomTask # implements ICustomTask
			getData: cheker.guard(Object..., () ->
				return [1, 2, 3]
			)

			getName: cheker.guard(String, -> "custom task")


		run = 0

		class CustomWorker # implements ICustomWorker
			running: false

			doWork: cheker.guard(undefined, ICustomTask, (task) ->
				running = true
				++run
				running = false
			)


		runTask = cheker.guard(undefined, IWorker(ITask), ITask, (worker, task) ->
			worker.doWork(task)
		)

		runSpecialTask = cheker.guard(undefined, ICustomWorker, ICustomTask, (worker, task) ->
			worker.doWork(task)
		)

		expect(run).to.be(0)
		runTask(new CustomWorker(), new CustomTask())
		expect(run).to.be(1)

		expect(run).to.be(1)
		runSpecialTask(new CustomWorker(), new CustomTask())
		expect(run).to.be(2)

		expect(run).to.be(2)
		task = {
			getData: -> ["nothing"]
			getName: -> "anonymous"
			running: true
		}
		runSpecialTask(new CustomWorker(), task)
		expect(run).to.be(3)


	it "should wrap functions which aren't guarded", ->
		func = -> "sup"
		accept = cheker.guard(String, cheker.Function(String), (f) -> f())
		result = accept(func)
		expect(result).to.be("sup")


	it "should wrap functions which aren't guarded in objects", ->
		obj = {
			prop: -> "sup"
		}

		accept = cheker.guard(String, {prop: cheker.Function(String)}, (f) -> f.prop())
		expect(accept(obj)).to.be("sup")


	it "should recognize that functions don't match when doing basic comparisons", ->
		signature = cheker.Function(String)
		expect(cheker.not(signature, -> 42)).to.be.ok()

# TODO array types


#	TODO is this valid?
#	it 'should work for a simple class type', ->
#
#		class MyClass
#			constructor: (@value) ->
#
#		expect(cheker.is(MyClass, new MyClass("a"))).to.be.ok()
#		expect(cheker.is(MyClass, MyClass)).to.not.be.ok()


# TODO object/literals tests for is/not

# TODO varargs
###
	it 'should support varargs'


	it 'should allow for varargs in typed function declarations', ->

		spec = {
			prop: Primitives.String
			func: cheker.Function({prop: "string"}, "*...")
		}

		obj = {
			prop: "something"
			func: cheker.guard({prop: "string"}, (string, number) -> {prop: "#{string} -- #{number}"})
		}

		expect(cheker.is(spec, obj)).to.be.ok()
		expect(cheker.not(spec, obj)).to.not.be.ok()
###
