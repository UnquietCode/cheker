module.exports = class HandlerRegistration
	constructor: (@action) ->

	unregister: ->
		@action?()
		@action = null
