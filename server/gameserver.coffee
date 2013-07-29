Player = require('./player')

module.exports = class GameServer
    constructor: (@io) ->
        @entities = {}
        @players = {}
        @playerCount = 0

        console.log 'new game server!'

        @io.sockets.on 'connection', (socket) =>
            console.log 'new connection!'

            socket.join('room')

            socket.on 'players_read', (data) =>
                socket.emit 'players_read', @players

            #Player CRUD
            socket.on 'ship_create', (data) =>
                newPlayer = new Player(socket,this, data)
                @onPlayerConnect(newPlayer)
                socket.emit 'ship_create', newPlayer.getState()
        
            socket.on 'ship_read', (data) =>
                socket.emit 'ship_read', @players[data.id]

            socket.on 'ship_update', (data) =>
                @updatePlayer(data)
                @broadcastPlayerUpdate(data)
                socket.emit 'ship_update', @players[data.id]

            socket.on 'ship_delete', (data) =>
                @removePlayer(data.id)
                socket.emit 'ship_delete', @players[data.id]

            socket.on 'disconnect', () =>
                @broadcastPlayerDelete(socket.id)
                @removePlayer(socket.id)

    run: () =>
        # Update every interval of 

    onPlayerConnect: (player) ->
        @addPlayer(player)
        
    addEntity: (entity) =>
        @entities[entity.id] = entity
    
    addPlayer: (player) =>
        if player?
            @players[player.id] = player.getState()

    updatePlayer: (player) =>
        @players[player.id] = player

    removePlayer: (id) =>
        delete @players[id]

    broadcastPlayerUpdate: (data) =>
        @io.sockets.in('room').emit('players_update',  @players[data.id])

    broadcastPlayerDelete: (id) =>
        @io.sockets.in('room').emit('players_delete', id)

    pushPlayers: (player) =>
        player.connection.emit 'players', @players