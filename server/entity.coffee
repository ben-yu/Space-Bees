THREE = require 'three'

module.exports = class Entity
    constructor: (@id, @type, @kind, pos, dir) ->
        @pos = new THREE.Vector3(pos.x,pos.y,pos.z)
        @dir = new THREE.Vector3(dir.x,dir.y,dir.z)

    setPosition: (pos) =>
        @pos = pos

    setRotation: (rot) =>
    	@rot = rot

    getState: =>
        return {'id':@id,'type':@type,'pos':@pos,'dir':@dir}
