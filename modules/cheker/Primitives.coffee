Enum = require('./Enum')


primitives = ["Null", "Undefined", "Number", "String", "Boolean", "Object", "Array", "Function", "Regex", "RegEx"]

Primitives = new (class extends Enum
	constructor: () ->
		map = {}
		map[p] = p.toLowerCase() for p in primitives
		super(map)
)

Signature = class
	constructor: (@rType, @types...) ->
	toString: -> "#{@rType} -> #{@types}"

functionHelper = (rType, types...) ->
	return new Primitives.Function.Signature(rType, types...)

functionHelper.marker = Primitives.Function.marker
functionHelper.value = Primitives.Function.value
Primitives.Function = functionHelper
Primitives.Function.Signature = Signature

module.exports = Primitives