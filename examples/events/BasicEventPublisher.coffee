cheker = require('../../cheker')
IEvent = require('./IEvent')
IEventHandler = require('./IEventHandler')
HandlerRegistration = require('./HandlerRegistration')


module.exports = cheker.narrow(IEvent, (EventType) ->
	class EventPublisher
		handlers: []

		publish: cheker.guard(undefined, EventType, (event) ->
			handler.handle(event) for handler in @handlers
		)

		subscribe: cheker.guard(HandlerRegistration, IEventHandler(EventType), (handler) ->
			if not handler
				throw new Error("must provide a valid handler")

			@handlers.push(handler)

			return new HandlerRegistration(() =>
				idx = @handlers.indexOf(handler)
				@handlers.splice(idx, 1) if idx >= 0
			)
		)
)