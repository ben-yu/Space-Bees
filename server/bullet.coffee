Entity = require './entity'
Player = require './player'
THREE = require 'three'
Ammo = require './lib/ammo.js'
Physijs = require('./lib/physi.js')(THREE,Ammo)

module.exports = class Bullet extends Entity
    constructor: (@connection, @server, data) ->
        @playerID = connection.id
        @shotID = data.shotID
        @startTime = +new Date()
        @startPos = new THREE.Vector3(data.pos.x,data.pos.y,data.pos.z)
        @speed = 50;
        @id = "#{connection.id}" + "#{data.shotID}"
        super(@id,"","",data.pos,data.dir)

        console.log @id

        @boundingBox = new Physijs.SphereMesh(new THREE.SphereGeometry(3), new THREE.MeshLambertMaterial({ opacity: 0, transparent: true }))
        @boundingBox.position.set(data.pos.x,data.pos.y,data.pos.z)

        @pos = @boundingBox.position

    update : =>
        #console.log 'bullet update'
        t = (+new Date()-@startTime)/1000 # in sec
        @pos.copy(@startPos).add(@dir.clone().multiplyScalar(@speed).multiplyScalar(t))

    getState: =>
        return {'id':@id, 'playerID':@playerID,'shotID':@shotID, 'type':@type,'pos':@pos,'dir':@dir}
