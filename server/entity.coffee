Cannon = require('./lib/cannon.js')

module.exports = class Entity
    constructor: (@id, @type, @kind, pos, dir) ->
        @pos = new Cannon.Vec3(pos.x,pos.y,pos.z)
        @dir = new Cannon.Vec3(dir.x,dir.y,dir.z)

    setPosition: (pos) =>
        @pos = pos

    setRotation: (rot) =>
    	@rot = rot

    getState: =>
        return {'id':@id,'type':@type,'pos':@pos,'dir':@dir}
