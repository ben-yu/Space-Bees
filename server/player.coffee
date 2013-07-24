Entity = require './entity'

module.exports = class Player extends Entity
    constructor: (@connection, @server, data) ->
        super(connection.id,"","",data.x,data.y,data.z)

    getState: () =>
        return {'id':@id,'type':@type,'x':@x,'y':@y,'z':@z}