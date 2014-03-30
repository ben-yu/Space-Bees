Entity = require './entity'
Bullet = require './bullet'
Cannon = require('./lib/cannon.js')

module.exports = class Player extends Entity
    constructor: (@connection, @server, data) ->
        super(connection.id,"","",data.pos,data.dir)
        @health = 100

        @boundingBox = new Cannon.RigidBody(1,new Cannon.Box(new Cannon.Vec3(data.box.x,data.box.y,data.box.z)))
        @boundingBox.position = @pos
        @boundingBox.addEventListener 'collide', (e) =>
            console.log 'Collision!'
            @connection.emit 'player_damage', @id

    getState: =>
        return {'id':@id,'type':@type,'pos':{'x':@pos.x,'y':@pos.y,'z':@pos.z},'dir':@dir, 'box': @minBox}
