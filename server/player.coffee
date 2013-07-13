Entity = require './entity'

module.exports = class Player extends Entity
	constructer: (id, @type, @kind, @x, @y, @z) ->
		super()