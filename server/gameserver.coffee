Player = require('./player')

module.exports = class GameServer
	constructor: (@socket) ->
        @players = {}
        @playerCount = 0
	run: =>

    onPlayerConnect: (player) =>
        

    addPlayer: (player) =>
        players[player.id] = player

    removePlayer: (player) =>
        delete this.players[player.id]