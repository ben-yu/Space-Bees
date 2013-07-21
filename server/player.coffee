Entity = require './entity'

module.exports = class Player extends Entity
    constructor: (@connection, @server) ->
        super(connection.id,"","",0,0,0)

        #Player CRUD
        @connection.on 'ship_create', (data) =>
            #console.log data
            @server.addPlayer
            @connection.emit 'ship_create', {id:1}
        
        @connection.on 'ship_read', (data) =>
            #console.log data
            @connection.emit 'ship_read', {id:1}

        @connection.on 'ship_update', (data) =>
            #console.log data
            @connection.emit 'ship_update', {id:1}

        @connection.on 'ship_delete', (data) =>
            #console.log data
            @connection.emit 'ship_delete', {id:1}