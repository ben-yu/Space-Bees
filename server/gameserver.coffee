_ = require 'underscore'
Cannon = require('./lib/cannon.js')
Player = require('./player')
Bullet = require('./bullet')


module.exports = class GameServer
    updatesPerSecond: 1/60

    constructor: (@io) ->
        @entities = {}
        @players = {}
        @enemies = {}
        @bullets = {}
        @missiles = {}
        @playerCount = 0

        @initWorld()
        @mapData = @generateMap()

        

        @io.sockets.on 'connection', (client) =>
            
            console.log 'New Connection!'
            client.join('room')

            client.emit 'gameStart', {'clientId':client.id,'mapData':@mapData}

            client.on 'disconnect', () =>
                @removeBullets(client.id)
                @broadcastPlayerDelete(client.id)
                @removePlayer(client.id)

            # Players CRUD

            client.on 'players_create', (data) =>
                #console.log 'New Player'
            client.on 'players_read', (data) =>
                client.emit 'players_read', _.map(@players, (v, k) -> return v.getState())
            client.on 'ship_create', (data) =>
                console.log 'New Player!'
                newPlayer = new Player(client, this, data)
                @addPlayer(newPlayer)
                client.emit 'ship_create', newPlayer.getState()
            client.on 'ship_read', (data) =>
                client.emit 'ship_read', @players[data.id].getState()
            client.on 'ship_update', (data) =>
                @updatePlayer(data)
                @broadcastPlayerUpdate(data)
                # TODO: send an ack
                #client.emit 'ship_update', @players[data.id].getState()
            client.on 'ship_delete', (data) =>
                @removePlayer(data.id)
                client.emit 'ship_delete', @players[data.id].getState()

            # Bullet CRUD

            client.on 'bullet_create', (data) =>
                console.log 'Shot!'
                console.log data.dir
                bullet = new Bullet(client,this, data)
                @addBullet(bullet,data.dir)
                client.emit 'bullet_create', bullet.getState()
            client.on 'bullet_read', (data) =>
                client.emit 'bullet_read', @bullets[data.id].getState()
            client.on 'bullet_update', (data) =>
                @updateBullet(data)
                @broadcastBulletUpdate(data)
            client.on 'bullet_delete', (data) =>
                @removeBullet(data.id)
                client.emit 'bullet_delete', @bullets[data.id].getState()
            client.on 'bullets_read', (data) =>
                #console.log _.map(@bullets, (v, k) -> return v.getState())
                client.emit 'bullets_read', _.map(@bullets, (v, k) -> return v.getState())

    initWorld: () =>
        @world = new Cannon.World()
        @world.quatNormalizeSkip = 0
        @world.quatNormalizeFast = false
        @world.gravity.set(0,0,0)
        @world.broadphase = new Cannon.NaiveBroadphase()

        setInterval(@update,@updatesPerSecond * 1000)

    generateMap: () =>
        cityWidth = 10
        cityHeight = 10

        buildingData = []

        for i in [0..cityWidth]
            for j in [0..cityHeight]
                buildingData[cityWidth*i + j] = {}
                buildingData[cityWidth*i + j].h  = Math.random() * Math.random() * Math.random() * Math.random() * 5000 + 1000
                buildingData[cityWidth*i + j].w  = 500
                buildingData[cityWidth*i + j].x = (i - cityWidth/2) * 1000
                buildingData[cityWidth*i + j].y = Math.random()*Math.PI*2
                buildingData[cityWidth*i + j].z = (j - cityHeight/2) * 1000
                #cannonBox =  new Cannon.RigidBody(1,new Cannon.Box(
                #    new Cannon.Vec3(buildingData[cityWidth*i + j].w/2,buildingData[cityWidth*i + j].h/2,buildingData[cityWidth*i + j].w/2)))
                #@world.add cannonBox

        return buildingData

                
    addEntity: (entity) =>
        @entities[entity.id] = entity
    
    addPlayer: (player) =>
        if player?
            @world.add player.boundingBox
            @players[player.id] = player
            @playerCount += 1

    updatePlayer: (playerData) =>
        @players[playerData.id].pos.set(playerData.pos.x,playerData.pos.y,playerData.pos.z)
        @players[playerData.id].dir = playerData.dir

    removePlayer: (id) =>
        if @players[id] != null
            @world.remove(@players[id].boundingBox)
            delete @players[id]
            @playerCount -= 1

    broadcastPlayerUpdate: (player) =>
        @io.sockets.in('room').emit('ship_update',  @players[player.id].getState())

    broadcastPlayerDelete: (id) =>
        @io.sockets.in('room').emit('players_delete', id)

    addBullet: (bullet,dir) =>
        if bullet?
            @bullets[bullet.id] = bullet
            @world.add bullet.boundingBox
            worldPoint = new Cannon.Vec3(0,0,0)
            console.log bullet.vel
            force = new Cannon.Vec3(bullet.impulse*bullet.vel.x,bullet.impulse*bullet.vel.y,bullet.impulse*bullet.vel.z)
            bullet.boundingBox.applyForce(force,worldPoint)
            setTimeout(@removeBullet,5000,bullet.id)            

    updateBullet: (bulletData) =>
        @bullets[bulletData.id].pos = bulletData.pos
        @bullets[bulletData.id].dir = bulletData.dir

    removeBullet: (id) =>
        @io.sockets.in('room').emit('bullets_delete', @bullets[id].getState())
        @world.remove(@bullets[id].boundingBox)
        delete @bullets[id]        

    removeBullets: (id) =>
        for k,v of @bullets
            if v.playerID is id
                @world.remove(@bullets[k].boundingBox)
                delete @bullets[k]

    broadcastBulletUpdate: (data) =>
        @io.sockets.in('room').emit('bullet_update',  @bullets[data.id])

    broadcastBulletDelete: (id) =>
        

    update: () =>
        if @playerCount > 0
            @world.step(@updatesPerSecond)
            #for k,v of @bullets
                #v.update()
                #@bullets[k].boundingBox.position.copy(@bullets[k].pos)
                #@bullets[k].boundingBox.__dirtyPosition = true
                #@bullets[k].boundingBox.rotation.copy(@bullets[k].dir)
                #@bullets[k].boundingBox.__dirtyRotation = true
            for k,v of @players
                # TODO: Check player position bounds
                @players[k].boundingBox.position.copy(@players[k].pos)
                #@players[k].boundingBox.quaternion.copy(@players[k].dir)
            @io.sockets.in('room').emit('players_update', _.map(@players, (v, k) -> return v.getState()))
            @io.sockets.in('room').emit('bullets_update', _.map(@bullets, (v, k) -> return v.getState()))
