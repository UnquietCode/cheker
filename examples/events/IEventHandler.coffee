cheker = require('../../cheker')
IEvent = require('./IEvent')

module.exports = cheker.narrow(IEvent, (EventType) -> {
	handle: cheker.Function(undefined, EventType)
})