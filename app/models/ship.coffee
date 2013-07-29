module.exports = class ShipModel extends Backbone.Model
    initialize : () =>
        @connection = window.socket
        @set "position", @position = @get("position") or new THREE.Vector3()
        @set "velocity", new THREE.Vector3(0, 0, 0)
        @falling = true
        @startDate = +new Date()
        @lastFire = 0
        @lastShot = 0
        @lastMove = +new Date()
        @life = @get("life") or 100
        @shield = @get("shield") or 100
        @lastFireMissile = 0
        @rotationV = new THREE.Vector3(0, 1, 0)
        @level = 0

        @mesh = null

        @loadModel()
        return

    update : ->
    loadModel : =>
        merged = new THREE.Geometry()

        @mesh = new THREE.Mesh(SpaceBees.Loader.get('geometries','ship'), new THREE.MeshNormalMaterial())
        @mesh.scale.set(15.0,15.0,15.0)
        @mesh.position.copy(@position)

    setControls : ->
    standardFire : ->
    advancedFire : ->
    move : ->
    damage : ->

    getState: () =>
        return {'id':@id,'type':@type,
        'x':@position.x,'y':@position.y,'z':@position.z
        'dir_x':@mesh.rotation.x,'dir_y':@mesh.rotation.y,'dir_z':@mesh.rotation.z}

    sync : (method, model, options) =>
        options.data ?= {}
        @connection.emit 'ship_' + method, model.getState(), options.data, (err, data) ->
            if err
                console.error "error in sync with #{method} #{@.name()} with server (#{err})"
            else
                options.success data

        @connection.on 'ship_' + method, (data) ->
            model.id = data.id
            model.position.x = data.x
            model.position.y = data.y
            model.position.z = data.z
            model.mesh.rotation.x = data.dir_x
            model.mesh.rotation.y = data.dir_y
            model.mesh.rotation.z = data.dir_z

    name: =>
        if @collection and @collection.name then return @collection.name else throw new Error "Socket model has no name (#{@.collection})"
