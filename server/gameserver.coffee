_ = require 'underscore'
THREE = require 'three'
Ammo = require './lib/ammo.js'
Physijs = require('./lib/physi.js')(THREE,Ammo)
Player = require('./player')
Bullet = require('./bullet')

module.exports = class GameServer
    updatesPerSecond: 5

    constructor: (@io) ->
        @entities = {}
        @players = {}
        @enemies = {}
        @bullets = {}
        @missiles = {}
        @playerCount = 0

        console.log 'New Game Server!'

        @io.sockets.on 'connection', (client) =>
            console.log 'new connection!'

            client.join('room')

            client.emit 'client_id', client.id

            client.on 'disconnect', () =>
                @removeBullets(client.id)
                @broadcastPlayerDelete(client.id)
                @removePlayer(client.id)

            client.on 'players_create', (data) =>
                console.log 'New Player'

            client.on 'players_read', (data) =>
                client.emit 'players_read', _.map(@players, (v, k) -> return v.getState())

            # Player CRUD
            client.on 'ship_create', (data) =>
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
                #client.emit 'ship_delete', @players[data.id].getState()

            # Bullet CRUD
            client.on 'bullet_create', (data) =>
                bullet = new Bullet(client,this, data)
                @addBullet(bullet)
                client.emit 'bullet_create', bullet.getState()
        
            client.on 'bullet_read', (data) =>
                client.emit 'bullet_read', @bullets[data.id].getState()

            client.on 'bullet_update', (data) =>
                @updateBullet(data)
                @broadcastBulletUpdate(data)
                client.emit 'bullet_update', @bullets[data.id].getState()

            client.on 'bullet_delete', (data) =>
                @removeBullet(data.id)
                client.emit 'bullet_delete', @bullets[data.id].getState()

            client.on 'bullets_read', (data) =>
                client.emit 'bullets_read', _.map(@bullets, (v, k) -> return v.getState())

            # Enemy CRUD
            client.on 'enemy_create', (data) =>
                newPlayer = new Enemy(client,this, data)
                @addPlayer(newPlayer)
                client.emit 'enemy_create', newPlayer.getState()
        
            client.on 'enemy_read', (data) =>
                client.emit 'enemy_read', _.map(@players, (v, k) -> return v.getState())

            client.on 'enemy_update', (data) =>
                @updatePlayer(data)
                @broadcastPlayerUpdate(data)
                client.emit 'enemy_update', _.map(@players, (v, k) -> return v.getState())

            client.on 'enemy_delete', (data) =>
                @removePlayer(data.id)
                client.emit 'enemy_delete', _.map(@players, (v, k) -> return v.getState())

        @initWorld()

    initWorld: () =>
        @scene = new Physijs.Scene
        @scene.setGravity(new THREE.Vector3(0, 0, 0))

        # load map mesh
        #@jsonLoader = new THREE.JSONLoader()
        #@jsonLoader.load '/public/models/city/city.js' , (a) =>
            #@map = new Pyhsijs.a


        setInterval(@update,1000)

    update: () =>
        @scene.simulate()
        @updateGroups()
                
    addEntity: (entity) =>
        @entities[entity.id] = entity
    
    addPlayer: (player) =>
        if player?
            @scene.add player.boundingBox
            @players[player.id] = player

    updatePlayer: (playerData) =>
        @players[playerData.id].pos = playerData.pos
        @players[playerData.id].dir = playerData.dir

    removePlayer: (id) =>
        delete @players[id]

    broadcastPlayerUpdate: (player) =>
        @io.sockets.in('room').emit('ship_update',  @players[player.id].getState())

    broadcastPlayerDelete: (id) =>
        @io.sockets.in('room').emit('players_delete', id)

    addBullet: (bullet) =>
        if bullet?
            @scene.add bullet.boundingBox
            bullet.boundingBox.setLinearVelocity({z: -10, y: 0, x: 0 })
            @bullets[bullet.id] = bullet

    updateBullet: (bulletData) =>
        @bullets[bulletData.id] = bullet.pos

    removeBullets: (id) =>
        for k,v of @bullets
            if v.playerID is id
                delete @bullets[k]

    broadcastBulletUpdate: (data) =>
        @io.sockets.in('room').emit('bullets_update',  @bullets[data.id])

    broadcastBulletDelete: (id) =>
        @io.sockets.in('room').emit('bullets_delete', id)

    updateGroups: () =>
        t = 300
        #for k,v of @players
            # TODO: Check player position bounds
            #@players[k].boundingBox.position.copy(@players[k].pos)
            #@players[k].boundingBox.__dirtyPosition = true
            #@players[k].boundingBox.rotation.copy(@players[k].dir)
            #@players[k].boundingBox.__dirtyRotation = true
        @io.sockets.in('room').emit('players_update', _.map(@players, (v, k) -> return v.getState()))
        @io.sockets.in('room').emit('bullets_update', _.map(@bullets, (v, k) -> return v.getState()))
