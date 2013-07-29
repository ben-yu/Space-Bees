Entity = require './entity'

module.exports = class Player extends Entity
    constructor: (@connection, @server, data) ->
        super(connection.id,"","",data.x,data.y,data.z)
        @dir_x = data.dir_x
        @dir_y = data.dir_y
        @dir_z = data.dir_z

    getState: () =>
        return {'id':@id,'type':@type,
        'x':@x,'y':@y,'z':@z,
        'dir_x':@dir_x,'dir_y':@dir_y,'dir_z':@dir_z}