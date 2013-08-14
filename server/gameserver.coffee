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

        @io.sockets.on 'connection', (socket) =>
            console.log 'new connection!'

            socket.join('room')

            socket.on 'disconnect', () =>
                @broadcastPlayerDelete(socket.id)
                @removePlayer(socket.id)

            socket.on 'players_read', (data) =>
                socket.emit 'players_read', @players

            #Player CRUD
            socket.on 'ship_create', (data) =>
                newPlayer = new Player(socket,this, data)
                @onPlayerConnect(newPlayer)
                socket.emit 'ship_create', newPlayer.getState()
                console.log 'Create Ship'
        
            socket.on 'ship_read', (data) =>
                socket.emit 'ship_read', @players[data.id]

            socket.on 'ship_update', (data) =>
                @updatePlayer(data)
                @broadcastPlayerUpdate(data)
                socket.emit 'ship_update', @players[data.id]

            socket.on 'ship_delete', (data) =>
                @removePlayer(data.id)
                socket.emit 'ship_delete', @players[data.id]

            #Bullet CRUD
            socket.on 'bullet_create', (data) =>
                bullet = new Bullet(socket,this, data)
                @addBullet(bullet)
                socket.emit 'bullet_create', bullet.getState()
        
            socket.on 'bullet_read', (data) =>
                socket.emit 'bullet_read', @bullets[data.id]

            socket.on 'bullet_update', (data) =>
                @updateBullet(data)
                @broadcastBulletUpdate(data)
                socket.emit 'bullet_update', @bullets[data.id]

            socket.on 'bullet_delete', (data) =>
                @removeBullet(data.id)
                socket.emit 'bullet_delete', @bullets[data.id]

            socket.on 'bullets_read', (data) =>
                socket.emit 'bullets_read', @bullets

            #Enemy CRUD
            socket.on 'enemy_create', (data) =>
                newPlayer = new Enemy(socket,this, data)
                @onPlayerConnect(newPlayer)
                socket.emit 'enemy_create', newPlayer.getState()
        
            socket.on 'enemy_read', (data) =>
                socket.emit 'enemy_read', @players[data.id]

            socket.on 'enemy_update', (data) =>
                @updatePlayer(data)
                @broadcastPlayerUpdate(data)
                socket.emit 'enemy_update', @players[data.id]

            socket.on 'enemy_delete', (data) =>
                @removePlayer(data.id)
                socket.emit 'enemy_delete', @players[data.id]

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

    removeBullet: (id) =>
        delete @bullets[id]

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
            #oldDir = new THREE.Vector3(v.dir.x,v.dir.y,v.dir.z)
            #newpos = new THREE.Vector3(v.pos.x,v.pos.y,v.pos.z)
            #v.pos = newpos.add(oldDir.multiplyScalar(t))
            @io.sockets.in('room').emit('bullets_update',  @bullets[k])
