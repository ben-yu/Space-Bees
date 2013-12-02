module.exports = class ShipModel extends Backbone.Model
    initialize : () =>
        @connection = window.socket
        @set "position", @position = @get("position") or new THREE.Vector3()
        @set "velocity", new THREE.Vector3(0, 0, 0)
        @scaleFactor = 15.0
        @startDate = +new Date()
        @lastFire = 0
        @lastShot = 0
        @lastMove = +new Date()
        @life = @get("life") or 100
        @shield = @get("shield") or 100
        @lastFireMissile = 0
        @rotationV = new THREE.Vector3(0, 1, 0)
        @level = 0
        @shotsFired = 0

        @mesh = null

        @loadModel()
        return

    update : ->
    loadModel : =>
        geom = SpaceBees.Loader.get('geometries','ship')
        geom.computeBoundingBox()
        @minBox = geom.boundingBox.min.multiplyScalar(@scaleFactor)
        @mesh = new THREE.Mesh(geom, new THREE.MeshNormalMaterial())
        @mesh.scale.set(@scaleFactor,@scaleFactor,@scaleFactor)
        @mesh.position.copy(@position)

    setControls : ->
    standardFire : ->
    advancedFire : ->
    move : ->
    damage : ->

    getState: () =>
        return {'id':@id,'type':@type,'pos':@position, 'dir':@mesh.rotation, 'box':@minBox}

    sync : (method, model, options) =>
        options.data ?= {}
        #if method is 'update' or 'read'
            #console.log method
        @connection.emit 'ship_' + method, model.getState(), options.data, (err, data) ->
            if err
                console.error "error in sync with #{method} #{@.name()} with server (#{err})"
            else
                options.success data

        @connection.on 'ship_' + method, (data) ->
            #console.log data
            if model.id is not data.id
                console.log 'ship_' + method
                model.position.copy(data.pos)
                model.mesh.rotation.copy(data.dir)

    name: =>
        if @collection and @collection.name then return @collection.name else throw new Error "Socket model has no name (#{@.collection})"
