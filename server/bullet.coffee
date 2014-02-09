Entity = require './entity'
Player = require './player'
Cannon = require('./lib/cannon.js')

module.exports = class Bullet extends Entity
    constructor: (@connection, @server, data) ->
        @playerID = connection.id
        @shotID = data.shotID
        @startTime = +new Date()
        @startPos = new Cannon.Vec3(data.pos.x,data.pos.y,data.pos.z)
        @impulse = 5000
        @vel = data.vel
        @id = "#{connection.id}" + "#{data.shotID}"
        super(@id,"","",data.pos,data.dir)

        console.log @id
        @boundingBox = new Cannon.RigidBody(1,new Cannon.Box(new Cannon.Vec3(1,1,20)))
        @boundingBox.initQuaternion = new Cannon.Quaternion(@dir.x,@dir.y,@dir.z,@dir.w)
        @boundingBox.position = @pos
    update : =>
        t = (+new Date()-@startTime)/1000 # in sec
        #@pos.copy(@startPos).add(@dir.clone().multiplyScalar(@speed).multiplyScalar(t))

    getState: =>
        return {'id':@id, 'playerID':@playerID,'shotID':@shotID, 'type':@type,'pos':@pos,'dir':@dir}
