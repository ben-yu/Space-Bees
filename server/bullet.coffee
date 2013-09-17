Entity = require './entity'
Player = require './player'
THREE = require 'three'
Ammo = require './lib/ammo.js'
Physijs = require('./lib/physi.js')(THREE,Ammo)

module.exports = class Bullet extends Entity
    constructor: (@connection, @server, data) ->
        @playerID = connection.id
        @shotID = data.shotID
        @id = "#{connection.id}" + "#{data.shotID}"
        super(@id,"","",data.pos,data.dir)

        @boundingBox = new Physijs.SphereMesh(new THREE.SphereGeometry(3), new THREE.MeshLambertMaterial({ opacity: 0, transparent: true }))
        @boundingBox.position.set(data.pos.x,data.pos.y,data.pos.z)

        @pos = @boundingBox.position

    getState: =>
        return {'id':@id, 'playerID':@playerID,'shotID':@shotID, 'type':@type,'pos':@pos,'dir':@dir}
