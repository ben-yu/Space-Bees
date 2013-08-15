THREE = require 'three'
Player = require('./player')
Bullet = require('./bullet')

module.exports = class GameServer
    updatesPerSecond: 30

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

            client.on 'players_read', (data) =>
                client.emit 'players_read', @players

            #Player CRUD
            client.on 'ship_create', (data) =>
                newPlayer = new Player(client,this, data)
                @onPlayerConnect(newPlayer)
                client.emit 'ship_create', newPlayer.getState()
                console.log 'Create Ship'
        
            client.on 'ship_read', (data) =>
                client.emit 'ship_read', @players[data.id]

            client.on 'ship_update', (data) =>
                @updatePlayer(data)
                @broadcastPlayerUpdate(data)
                client.emit 'ship_update', @players[data.id]

            client.on 'ship_delete', (data) =>
                @removePlayer(data.id)
                client.emit 'ship_delete', @players[data.id]

            #Bullet CRUD
            client.on 'bullet_create', (data) =>
                bullet = new Bullet(client,this, data)
                @addBullet(bullet)
                client.emit 'bullet_create', bullet.getState()
        
            client.on 'bullet_read', (data) =>
                client.emit 'bullet_read', @bullets[data.id]

            client.on 'bullet_update', (data) =>
                @updateBullet(data)
                @broadcastBulletUpdate(data)
                client.emit 'bullet_update', @bullets[data.id]

            client.on 'bullet_delete', (data) =>
                @removeBullet(data.id)
                client.emit 'bullet_delete', @bullets[data.id]

            client.on 'bullets_read', (data) =>
                client.emit 'bullets_read', @bullets

            #Enemy CRUD
            client.on 'enemy_create', (data) =>
                newPlayer = new Enemy(client,this, data)
                @onPlayerConnect(newPlayer)
                client.emit 'enemy_create', newPlayer.getState()
        
            client.on 'enemy_read', (data) =>
                client.emit 'enemy_read', @players[data.id]

            client.on 'enemy_update', (data) =>
                @updatePlayer(data)
                @broadcastPlayerUpdate(data)
                client.emit 'enemy_update', @players[data.id]

            client.on 'enemy_delete', (data) =>
                @removePlayer(data.id)
                client.emit 'enemy_delete', @players[data.id]

        @run()

    run: () =>

        setInterval () =>
            @updateGroups()
        , 1000 / @updatesPerSecond

    onPlayerConnect: (player) ->
        @addPlayer(player)
        
    addEntity: (entity) =>
        @entities[entity.id] = entity
    
    addPlayer: (player) =>
        if player?
            @players[player.id] = player.getState()

    addBullet: (bullet) =>
        if bullet?
            @bullets[bullet.id] = bullet.getState()

    updatePlayer: (player) =>
        @players[player.id] = player

    updateBullet: (bullet) =>
        @bullets[bullet.id] = bullet

    removePlayer: (id) =>
        delete @players[id]

    removeBullets: (id) =>
        for k,v of @bullets
            if v.playerID is id
                delete @bullets[k]

    broadcastPlayerUpdate: (data) =>
        @io.sockets.in('room').emit('players_update',  @players[data.id])

    broadcastBulletUpdate: (data) =>
        @io.sockets.in('room').emit('bullets_update',  @bullets[data.id])

    broadcastPlayerDelete: (id) =>
        @io.sockets.in('room').emit('players_delete', id)

    broadcastBulletDelete: (id) =>
        @io.sockets.in('room').emit('bullets_delete', id)

    pushPlayers: (player) =>
        player.connection.emit 'players', @players

    updateGroups: () =>
        t = 1000 / @updatesPerSecond
        for k,v of @bullets
            oldDir = new THREE.Vector3(v.dir.x,v.dir.y,v.dir.z)
            newpos = new THREE.Vector3(v.pos.x,v.pos.y,v.pos.z)
            v.pos = newpos.add(oldDir.multiplyScalar(t))
            @io.sockets.in('room').emit('bullets_update',  @bullets[k])
