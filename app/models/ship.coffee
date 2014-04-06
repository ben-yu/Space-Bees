module.exports = class ShipModel extends Backbone.Model
    initialize : () =>
        @connection = window.socket
        @set "position", @position = @get("position") or new THREE.Vector3(0,2000,100)
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
        @set "speed", @speed = 0

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

        physicsMaterial = new CANNON.Material("slipperyMaterial")
        @cannonBox =  new CANNON.RigidBody(1,new CANNON.Box(new CANNON.Vec3(@minBox.x,@minBox.y,@minBox.z),physicsMaterial))
        @cannonBox.position.set(@position.x,@position.y,@position.z)
        @cannonBox.linearDamping = 0.9

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
            #console.log model
            if not model.id?
                console.log 'ship_' + method
                model.id = data.id
                model.position.copy(data.pos)
                model.rotationV.copy(data.dir)

    name: =>
        if @collection and @collection.name then return @collection.name else throw new Error "Socket model has no name (#{@.collection})"
