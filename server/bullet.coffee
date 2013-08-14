Entity = require './entity'

module.exports = class Bullet extends Entity
    constructor: (@connection, @server, data) ->
        @playerID = connection.id
        @shotID = data.shotID
        super("#{connection.id}" + "#{data.shotID}","","",data.pos,data.dir)

    getState: =>
        return {'id':@id, 'playerID':@playerID,'shotID':@shotID, 'type':@type,'pos':@pos,'dir':@dir}
