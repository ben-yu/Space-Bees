Player = require('./player')

module.exports = class GameServer
    constructor: (@io) ->
        @entities = {}
        @players = {}
        @playerCount = 0

        console.log 'new game server!'

        @io.sockets.on 'connection', (socket) =>
            console.log 'new connection!'
            @onPlayerConnect(new Player(socket,this))

            socket.on 'players_read', (data) =>
                #socket.emit 'players_read', @players

    onPlayerConnect: (player) ->
        @addPlayer(player)
        
    addEntity: (entity) =>
        @entities[entity.id] = entity
    
    addPlayer: (player) =>
        @players[player.id] = player

    updatePlayer: (player) =>
        @players[player.id] = player

    removePlayer: (player) =>
        delete @players[player.id]

    pushPlayers: (player) =>
        player.connection.emit 'players', @players