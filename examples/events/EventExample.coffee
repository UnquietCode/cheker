cheker = require('../../cheker')
Enum = cheker.Enum
expect = require('expect.js')
log = console.log

IEvent = require('./IEvent')
IEventHandler = require('./IEventHandler')
IEventPublisher = require('./IEventPublisher')
BasicEventPublisher = require('./BasicEventPublisher')
HandlerRegistration = require('./HandlerRegistration')


# extend the basic event to a custom type
ICustomEvent = cheker.extend(IEvent, {
	color: String
})

# create an implementation for the custom event type
class MyCustomEvent # implements ICustomEvent
	constructor: (@color) ->
	source: "1234"


handled = []

# create an implementation for the event handler
class MyEventHandler # implements IEventHandler
	handle: cheker.guard(undefined, ICustomEvent, (event) ->
		handled.push(event.color)
	)


# create a function which accepts only a custom event publisher,
# and then publishes a custom event
acceptPublisher = cheker.guard(undefined, IEventPublisher(ICustomEvent), (publisher) ->
	handler = new MyEventHandler()
	registration = publisher.subscribe(handler)

	event = new MyCustomEvent("Blue")
	publisher.publish(event)

	registration.unregister()
	publisher.publish(event)
)


# execute the function with a generic event publisher
acceptPublisher(new (BasicEventPublisher(ICustomEvent)))

# expect that it was executed once (then unregistered)
expect(handled.length).to.be(1)
expect(handled[0]).to.be("Blue")


# try to execute with an insufficient publisher
fail = false
try
	acceptPublisher({})
	fail = true
catch e
	# nothing

expect(fail).to.be(false)
