Entity = require './entity'

module.exports = class Player extends Entity
    constructor: (@connection, @server, data) ->
        super(connection.id,"","",data.pos,data.dir)
