Entity = require './entity'
Player = require './player'
THREE = require 'three'
Physijs = require('./lib/physi_nodemaster.js')(THREE)

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
        @boundingBox = new Physijs.BoxMesh(new THREE.CubeGeometry(1,1,20),new THREE.MeshBasicMaterial({ color: 0x888888 }))
        @boundingBox.position = @pos
    update : =>
        t = (+new Date()-@startTime)/1000 # in sec
        @pos.copy(@startPos).add(@dir.clone().multiplyScalar(@speed).multiplyScalar(t))

    getState: =>
        return {'id':@id, 'playerID':@playerID,'shotID':@shotID, 'type':@type,'pos':@pos,'dir':@dir}
