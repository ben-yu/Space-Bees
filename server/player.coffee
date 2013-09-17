Entity = require './entity'
Bullet = require './bullet'
THREE = require 'three'
Ammo = require './lib/ammo.js'
Physijs = require('./lib/physi.js')(THREE,Ammo)

module.exports = class Player extends Entity
    constructor: (@connection, @server, data) ->
        super(connection.id,"","",data.pos,data.dir)
        @health = 100

        @boundingBox = new Physijs.SphereMesh(new THREE.CubeGeometry(data.box.x,data.box.y,data.box.z), new THREE.MeshLambertMaterial({ opacity: 0, transparent: true }))
        @boundingBox.position = @pos
        @boundingBox.addEventListener 'collision', (other_object, linear_velocity, angular_velocity) ->
            if other_object instanceof Bullet
                @connection.emit 'player_damage', @id

    getState: =>
        return {'id':@id,'type':@type,'pos':@pos,'dir':@dir, 'box': @minBox}
