Entity = require './entity'
Bullet = require './bullet'
THREE = require 'three'
Ammo = require './lib/ammo.js'
Physijs = require('./lib/physi.js')(THREE,Ammo)

module.exports = class Player extends Entity
    constructor: (@connection, @server, data) ->
        super(connection.id,"","",data.pos,data.dir)
        @health = 100

        @boundingBox = new Physijs.BoxMesh(new THREE.CubeGeometry(data.box.x,data.box.y,data.box.z), new THREE.MeshBasicMaterial({ color: 0x888888 }))
        @boundingBox.position = @pos
        @boundingBox.addEventListener 'collision', (other_object, linear_velocity, angular_velocity) =>
            console.log 'Collision!'
            if other_object instanceof Player
                @connection.emit 'player_damage', @id

    getState: =>
        return {'id':@id,'type':@type,'pos':@pos,'dir':@dir, 'box': @minBox}
