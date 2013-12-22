_ = require 'underscore'
THREE = require 'three'
Ammo = require './lib/ammo.js'
Physijs = require('./lib/physi.js')(THREE,Ammo)
Player = require('./player')
Bullet = require('./bullet')

module.exports = class GameServer
    updatesPerSecond: 10

    constructor: (@io) ->
        @entities = {}
        @players = {}
        @enemies = {}
        @bullets = {}
        @missiles = {}
        @playerCount = 0

        console.log 'New Game Server!!!!!'

        @io.sockets.on 'connection', (client) =>
            console.log 'new connection!'

            client.join('room')

            client.emit 'client_id', client.id

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
                #console.log 'New Player!'
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
                bullet = new Bullet(client,this, data)
                @addBullet(bullet)
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

        @initWorld()

    initWorld: () =>
        #@scene = new Physijs.Scene
        #@scene.setGravity(new THREE.Vector3(0, 0, 0))

        # load map mesh
        #@jsonLoader = new THREE.JSONLoader()
        #@jsonLoader.load '/public/models/city/city.js' , (a) =>
            #@map = new Pyhsijs.a
        setInterval(@update,10)
                
    addEntity: (entity) =>
        @entities[entity.id] = entity
    
    addPlayer: (player) =>
        if player?
            #@scene.add player.boundingBox
            @players[player.id] = player

    updatePlayer: (playerData) =>
        @players[playerData.id].pos = playerData.pos
        @players[playerData.id].dir = playerData.dir

    removePlayer: (id) =>
        if @players[id] != null
            @scene.remove(@players[id].boundingBox)
            delete @players[id]

    broadcastPlayerUpdate: (player) =>
        @io.sockets.in('room').emit('ship_update',  @players[player.id].getState())

    broadcastPlayerDelete: (id) =>
        @io.sockets.in('room').emit('players_delete', id)

    addBullet: (bullet) =>
        if bullet?
            @bullets[bullet.id] = bullet
            #@scene.add bullet.boundingBox
            #bullet.boundingBox.setLinearVelocity({z: -10, y: 0, x: 0 })

    updateBullet: (bulletData) =>
        @bullets[bulletData.id].pos = bulletData.pos
        @players[bulletData.id].dir = bulletData.dir

    removeBullets: (id) =>
        for k,v of @bullets
            if v.playerID is id
                #@scene.remove(@bullets[k].boundingBox)
                delete @bullets[k]

    broadcastBulletUpdate: (data) =>
        @io.sockets.in('room').emit('bullet_update',  @bullets[data.id])

    broadcastBulletDelete: (id) =>
        @io.sockets.in('room').emit('bullets_delete', id)

    update: () =>
        t = 100
        #console.log 'update'
        for k,v of @bullets
            v.update()
        #for k,v of @players
            # TODO: Check player position bounds
            #@players[k].boundingBox.position.copy(@players[k].pos)
            #@players[k].boundingBox.__dirtyPosition = true
            #@players[k].boundingBox.rotation.copy(@players[k].dir)
            #@players[k].boundingBox.__dirtyRotation = true
        @io.sockets.in('room').emit('players_update', _.map(@players, (v, k) -> return v.getState()))
        @io.sockets.in('room').emit('bullets_update', _.map(@bullets, (v, k) -> return v.getState()))
