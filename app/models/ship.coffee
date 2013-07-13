module.exports = class ShipModel extends Backbone.Model
    initialize : =>
        @socket = new io.connect('http://localhost')
        @set "position", @position = @get("position") or new THREE.Vector3()
        #console.log @get("position")
        @set "velocity", new THREE.Vector3(0, 0, 0)
        @falling = true
        @startDate = +new Date()
        @lastFire = 0
        @lastShot = 0
        @lastMove = +new Date()
        @life = @get("life") or 100
        @lastFireMissile = 0
        @rotationV = new THREE.Vector3(0, 1, 0)
        @level = 0

        @mesh = null

        @loadModel()
        return

    update : ->
    loadModel : =>
        #self = this
        #loader = new THREE.JSONLoader()
        #loader.load 'models/missiles/hellfire.js',  ( geometry, materials ) =>
        merged = new THREE.Geometry()

        body = new THREE.Mesh(new THREE.CylinderGeometry(10,20,50), new THREE.MeshNormalMaterial())
        body.rotation.x = -Math.PI / 2
        wings = new THREE.Mesh(new THREE.CubeGeometry(80,5,10), new THREE.MeshNormalMaterial())
        wings.position.z = 20
        THREE.GeometryUtils.merge(merged, body)
        THREE.GeometryUtils.merge(merged, wings)
        @mesh = new THREE.Mesh(merged, new THREE.MeshNormalMaterial())

    setControls : ->
    standardFire : ->
    advancedFire : ->
    move : ->
    damage : ->

    sync : (method, model, options) =>
        #console.log method
        #options.data ?= {}
        @socket.emit method, model.toJSON(), options.data, (err, data) =>
            console.log "SEND!"
            if err then console.error "error in sync with #{method} #{@.name()} with server (#{err})" else options.success(data)

    name: =>
        if @collection and @collection.name then return @collection.name else throw new Error "Socket model has no name (#{@.collection})"
