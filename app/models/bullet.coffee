module.exports = class Bullet extends Backbone.Model
    initialize : =>
        @startTime = +new Date()

        @connection = window.socket
        @socket = @get("socket")
        @playerID = @get("session_id")
        @shotID = @get("shotID")

        @position = @get("position").clone()
        @maxDist = @get("maxDist") or 10000
        @speed = 500
        @velocity = @get("velocity")

        @mesh = new THREE.Mesh(new THREE.CylinderGeometry(1,1,20), new THREE.MeshNormalMaterial())
        @mesh.position = @position
        #@mesh.rotation.copy(@velocity)
        #console.log(@velocity)
        return

    update : =>
        t = (+new Date()-@startTime)/1000 # in sec
        @position.copy(@startPos).add(@velocity.clone().multiplyScalar(t))

    getState: () =>
        return {'id':@id, 'playerID':@playerID,'shotID':@shotID ,'type':@type,'pos':@position, 'dir':@velocity}

    sync : (method, model, options) =>
        options.data ?= {}
        @connection.emit 'bullet_' + method, model.getState(), options.data, (err, data) ->
            if err
                console.error "error in sync with #{method} #{@.name()} with server (#{err})"
            else
                options.success data

        @connection.on 'bullet_' + method, (data) =>
            if model.id is data.id
                model.position.copy(data.pos)
            #model.mesh.rotation.copy(data.dir)