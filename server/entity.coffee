module.exports = class Entity
	constructor: (id, @type, @kind, @x, @y, @z) ->
		@id = id

	setPosition: (x,y,z) =>
		@x = x
		@y = y
		@z = z

	getState: () =>
		return {'id':@id,'type':@type,'x':@x,'y':@y,'z':@z}
