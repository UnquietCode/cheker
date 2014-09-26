Enum = require('./Enum')


primitives = ["Null", "Undefined", "Number", "String", "Boolean", "Object", "Array", "Function", "Regex", "RegEx"]

Primitives = new (class extends Enum
	constructor: () ->
		map = {}
		map[p] = p.toLowerCase() for p in primitives
		super(map)
)

functionHelper = (types...) ->
	return (rType) ->


functionHelper.marker = Primitives.Function.marker
functionHelper.value = Primitives.Function.value
Primitives.Function = functionHelper

module.exports = Primitives