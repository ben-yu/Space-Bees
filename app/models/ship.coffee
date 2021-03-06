ParticlePool = require 'lib/particlepool'

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

        @particlesLength = 100
        @mesh = null

        @loadModel()
        @createExhaust()
        return

    update : ->
    loadModel : =>
        geom = SpaceBees.Loader.get('geometries','ship')
        geom.computeBoundingBox()
        @minBox = geom.boundingBox.min.multiplyScalar(@scaleFactor)
        @mesh = new THREE.Mesh(geom, new THREE.MeshNormalMaterial())
        @mesh.scale.set(@scaleFactor,@scaleFactor,@scaleFactor)
        @mesh.position.set(@position.x,@position.y,@position.z)

        @group = new THREE.Object3D()
        @group.add @mesh
        @group.position.copy(@position)

        # - CannonJS Model
        physicsMaterial = new CANNON.Material("slipperyMaterial")
        @cannonBox =  new CANNON.RigidBody(1,new CANNON.Box(new CANNON.Vec3(@minBox.x,@minBox.y,@minBox.z),physicsMaterial))
        @cannonBox.position.set(@position.x,@position.y,@position.z)
        @cannonBox.linearDamping = 0.9

    createExhaust : =>
        # - Exhaust Particle System
        #sprite = @generateExhaustSprite()
        #texture = new THREE.Texture sprite
        #texture.needsUpdate = true

        @particles = new THREE.Geometry()
        for i in [0..@particlesLength]
            pX = Math.random() * @position.x - Math.random() * 20
            pY = Math.random() * @position.x - Math.random() * 20
            pZ = Math.random() * @position.x - Math.random() * 20
            @particles.vertices.push new THREE.Vertex(new THREE.Vector3(pX, pY, pZ))
            #ParticlePool.add i

        shaderMaterial = pMaterial = new THREE.ParticleBasicMaterial({
            color: 0xFFFFFF
            size: 20
        })

        @particleCloud = new THREE.ParticleSystem( @particles, shaderMaterial )
        @particleCloud.dynamic = true
        @particleCloud.sortParticles = true

        #@values_size = @attributes.size.value
        #@values_color = @attributes.pcolor.value

        for i in [0..@particlesLength]
            #@values_size[i] = 50
            #@values_color[i] = new THREE.Color(0x000000)
            @particles.vertices[i].set( Number.POSITIVE_INFINITY, Number.POSITIVE_INFINITY, Number.POSITIVE_INFINITY)

        @group.add @particleCloud
        @particleCloud.position.set(@position.x,@position.y,@position.z)

        #sparksEmitter = new SPARKS.Emitter( new SPARKS.SteadyCounter( 500 ) )
        #emitterpos = new THREE.Vector3( 0, 0, 0 )
        ###
        sparksEmitter.addInitializer( new SPARKS.Position( new SPARKS.PointZone( @position ) ) )
        sparksEmitter.addInitializer( new SPARKS.Lifetime( 1, 15 ))
        sparksEmitter.addInitializer( new SPARKS.Target( null, @setTargetParticle ) )
        sparksEmitter.addInitializer( new SPARKS.Velocity( new SPARKS.PointZone( new THREE.Vector3( 0, -5, 1 ) ) ) )
        sparksEmitter.addAction( new SPARKS.Age() )
        sparksEmitter.addAction( new SPARKS.Accelerate( 0, 0, -50 ) )
        sparksEmitter.addAction( new SPARKS.Move() )
        sparksEmitter.addAction( new SPARKS.RandomDrift( 90, 100, 2000 ) )

        sparksEmitter.addCallback( "created", @onParticleCreated )
        sparksEmitter.addCallback( "dead", @onParticleDead )
        sparksEmitter.start()
        ###

    generateExhaustSprite : ->
        canvas = document.createElement 'canvas'
        canvas.width = 128
        canvas.height = 128
        context = canvas.getContext '2d'

        context.beginPath()
        context.arc( 64, 64, 60, 0, Math.PI * 2, false)
        context.lineWidth = 0.5
        context.stroke()
        context.restore()

        gradient = context.createRadialGradient( canvas.width / 2, canvas.height / 2, 0, canvas.width / 2, canvas.height / 2, canvas.width / 2 )
        gradient.addColorStop( 0, 'rgba(255,255,255,1)' )
        gradient.addColorStop( 0.2, 'rgba(255,255,255,1)' )
        gradient.addColorStop( 0.4, 'rgba(200,200,200,1)' )
        gradient.addColorStop( 1, 'rgba(0,0,0,1)' )

        context.fillStyle = gradient
        context.fill()
        return canvas

    onParticleCreated : (p) =>
        #position = p.position
        #p.target.position = position

        target = p.target
        if target
            @particles.vertices[target] = @position

    onParticleDead : (p) =>
        target = p.target
        if target
            #@values_color[target].setRGB 0,0,0
            @particles.vertices[target].set Number.POSITIVE_INFINITY, Number.POSITIVE_INFINITY, Number.POSITIVE_INFINITY
            ParticlePool.add p.target

    setTargetParticle : () ->
        target = ParticlePool.get()
        #@values_size[ target ] = Math.random() * 200 + 100
        return target

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
