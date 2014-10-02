cheker = require('../../cheker')
IEvent = require('./IEvent')
IEventHandler = require('./IEventHandler')
HandlerRegistration = require('./HandlerRegistration')


module.exports = cheker.narrow(IEvent, (EventType) -> {
	publish: cheker.Function(undefined, EventType)
	subscribe: cheker.Function(HandlerRegistration, IEventHandler(EventType))
})