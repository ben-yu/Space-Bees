module.exports = class Entity
	constructor: (id, @type, @kind, @x, @y, @z) ->
		@id = parseInt(id)

	setPosition: (x,y,z) =>
		@x = x
		@y = y
		@z = z

	getState: () =>
		return [parseInt(@id),@kind,@x,@y,@z]
