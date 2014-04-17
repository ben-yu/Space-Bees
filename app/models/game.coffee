ActivePlayers = require 'collections/activeplayers'
Bee = require 'models/bee'
Ship = require 'models/ship'
Missile = require 'models/missile'
Bullet = require 'models/bullet'
Bullets = require 'collections/bullets'
LockedControls = require 'lib/lockedcontrols'
ChaseCamera = require 'lib/chasecamera'
HealthbarView = require 'views/healthbar'
MapGenerator = require 'lib/mapgenerator'

module.exports = class Game extends Backbone.Model
    initialize: ->
        @lastFireStandard = +new Date()
        @lastFireMissile = +new Date()

        @clock = new THREE.Clock()
        @objects = []
        @pickingObjects = []
        @materials = {}

    start: (data) =>
        console.warn = () ->
        #console.log = () ->
        container = $('#game')

        @session_id = data.clientId

        WIDTH = window.innerWidth
        HEIGHT = window.innerHeight

        # - Cursor
        cursorOverlay = document.getElementById('cursorOverlay')
        cursorOverlay.width = WIDTH
        cursorOverlay.height = HEIGHT
        cursorOverlay.style.width = WIDTH
        cursorOverlay.style.height = HEIGHT
        cursorOverlay.style.top = 0
        cursorOverlay.style.left = 0
        cursorOverlay.style.position = 'absolute'
        @context = cursorOverlay.getContext('2d')

        # - Camera

        VIEW_ANGLE = 45
        ASPECT = WIDTH / HEIGHT
        NEAR = 0.1
        FAR = 2000000

        @camera = new THREE.PerspectiveCamera VIEW_ANGLE, ASPECT, NEAR, FAR
        @projector = new THREE.Projector()

        # - CannonJS World
        @cannonWorld = new CANNON.World()
        @cannonWorld.quatNormalizeSkip = 0
        @cannonWorld.quatNormalizeFast = false
        solver = new CANNON.GSSolver()
        solver.iterations = 7
        solver.tolerance = 0.1
        @cannonWorld.defaultContactMaterial.contactEquationStiffness = 1e9
        @cannonWorld.defaultContactMaterial.contactEquationRegularizationTime = 4
        @cannonWorld.solver = new CANNON.SplitSolver(solver)
        @cannonWorld.solver = solver
        @cannonWorld.gravity.set(0,0,0)
        @cannonWorld.broadphase = new CANNON.NaiveBroadphase()
        @cannonWorld.solver.iterations = 7

        physicsMaterial = new CANNON.Material "slipperyMaterial"
        physicsContactMaterial = new CANNON.ContactMaterial physicsMaterial, physicsMaterial, 0.0, 0.3
        @cannonWorld.addContactMaterial physicsContactMaterial

        # - Map

        @scene = new THREE.Scene
        mapGen = new MapGenerator()
        @renderer = new THREE.WebGLRenderer { antialias: false }
        
        mapGen.createMap(@scene,@cannonWorld,@renderer,data.mapData)
        @renderer.setClearColor(@scene.fog.color,1)

        ### - Mouse Lock-on
        @pickingScene = new THREE.Scene
        @pickingTexture = new THREE.WebGLRenderTarget( window.innerWidth, window.innerHeight )
        @pickingTexture.generateMipmaps = false


        @pickRenderer = new THREE.WebGLRenderer( { antialias: true } )
        @pickRenderer.setClearColor(0xffffff)
        @pickRenderer.sortObjects = false
        @pickRenderer.setSize( window.innerWidth, window.innerHeight )
        ###

        # Players
        @players = new ActivePlayers([],{parentScene:@scene, selfId:@session_id})
        @players.fetch()

        # Player's ship
        @ship = new Ship()
        
        @scene.add @camera
        @scene.add @ship.mesh
        @scene.add @ship.particleCloud

        SpaceBees.Views.HealthBar = new HealthbarView({model: @ship})

        @ship.bind 'change:speed', () =>
            SpaceBees.Views.HealthBar.speedIndicator.text(Math.floor(@ship.get('speed')) + 'm/s')

        @controls = new LockedControls @ship

        @ship.position = @controls.targetObject.position
        @ship.rotationV = @controls.targetObject.rotation

        @cannonWorld.add @controls.cannonBody

        @chasecamera = new ChaseCamera @camera, @ship.mesh


        # Projectiles
        @bullets = new Bullets([],{parentScene:@scene, selfId:@session_id})
        @bullets.fetch()
        @missiles = new Backbone.Collection()

        ###
        # Scene set-up
        ###

        # Lighting
        ambient = 0x555555
        diffuse = 0xffffff
        specular = 0xffffff
        shininess = 42
        scale = 23

        @scene.add new THREE.AmbientLight(ambient)

        sun = new THREE.DirectionalLight( diffuse, 1.5, 30000 )
        sun.position.set( -4000, 1200, 1800 )
        sun.lookAt new THREE.Vector3()
        @scene.add sun

        @renderer.setSize WIDTH, HEIGHT

        # Post-processing
        @renderer.autoClear = false

        renderTargetParameters = { minFilter: THREE.LinearFilter, magFilter: THREE.LinearFilter, format: THREE.RGBFormat, stencilBuffer: false }
        renderTarget = new THREE.WebGLRenderTarget WIDTH, HEIGHT, renderTargetParameters

        @effectSave = new THREE.SavePass( new THREE.WebGLRenderTarget( WIDTH, HEIGHT, renderTargetParameters ) )
        @effectBlend = new THREE.ShaderPass( THREE.BlendShader, "tDiffuse1" )
        effectFXAA = new THREE.ShaderPass( THREE.FXAAShader )
        effectVignette = new THREE.ShaderPass( THREE.VignetteShader )
        effectBleach = new THREE.ShaderPass( THREE.BleachBypassShader )
        effectBloom = new THREE.BloomPass( 0.25 )

        effectFXAA.uniforms[ 'resolution' ].value.set( 1 / WIDTH, 1 / HEIGHT )

        # tilt shift
        hblur = new THREE.ShaderPass( THREE.HorizontalTiltShiftShader )
        vblur = new THREE.ShaderPass( THREE.VerticalTiltShiftShader )

        bluriness = 2

        hblur.uniforms[ 'h' ].value = bluriness / WIDTH
        vblur.uniforms[ 'v' ].value = bluriness / HEIGHT
        hblur.uniforms[ 'r' ].value = vblur.uniforms[ 'r' ].value = 0.35
        
        effectVignette.uniforms[ "offset" ].value = 1.025
        effectVignette.uniforms[ "darkness" ].value = 1.25

        # Motion Blur
        @effectBlend.uniforms[ 'tDiffuse2' ].value = @effectSave.renderTarget
        @effectBlend.uniforms[ 'mixRatio' ].value = 0.65

        renderModel = new THREE.RenderPass( @scene, @camera )

        effectVignette.renderToScreen = true

        @composer = new THREE.EffectComposer( @renderer, renderTarget )
        @composer.addPass( renderModel )
        @composer.addPass( effectFXAA )
        @composer.addPass( @effectBlend )
        @composer.addPass( @effectSave )
        @composer.addPass( effectBloom )
        @composer.addPass( effectBleach )
        @composer.addPass( hblur )
        @composer.addPass( vblur )
        @composer.addPass( effectVignette )

        pointerLock = require 'lib/pointerlock'
        pointerLock(container,@renderer,@controls)

        bg_sound = new Howl({
            urls: ['sounds/background/8_bit.mp3'],
            loop: true
        })

        @gameloop()
        return

    initPointerLock : () ->

    initMap : () ->

    addPlayer: (player) =>
        @players.add(player)
        @scene.add(player.mesh)

    addToPicking: (entity) =>
        #geom = new THREE.CubeGeometry(entity.minBox.x,entity.minBox.y,entity.minBox.z)
        geom = new THREE.CubeGeometry(1,1,1)
        color = new THREE.Color(5)
        mesh = new THREE.Mesh(geom)
        @applyVertexColors(geom,color)
        mesh.position = new THREE.Vector3(0,0,0)
        @pickingObjects.push(mesh)
        @pickingScene.add mesh, new THREE.MeshBasicMaterial( { vertexColors: THREE.VertexColors } )

    pickObject: (x,y) =>
        @pickRenderer.render( @pickingScene, @camera, @pickingTexture )
        gl = @pickRenderer.getContext()

        pixelBuffer = new Uint8Array( 4 )
        gl.readPixels(x, y, 1, 1, gl.RGBA, gl.UNSIGNED_BYTE, pixelBuffer )

        #interpret the pixel as an ID
        id = ( pixelBuffer[0] << 16 ) | ( pixelBuffer[1] << 8 ) | ( pixelBuffer[2] )
        return id

    lockOnTarget: (x,y) ->
        #@target_id = @pickObject(x,y)

    applyVertexColors: (geom, color) ->
        for f in geom.faces
            for vertexColor in f.vertexColors
                vertexColor = color

    fire: (type) =>
        m2 = new THREE.Matrix4()
        m2.multiplyMatrices(m2,@controls.targetObject.matrix)
        m2.multiplyScalar(1/@ship.scaleFactor)
        newDir = new THREE.Vector3(0,0,-1)
        switch type
            when 'standard'
                @ship.shotsFired += 1
                bullet = new Bullet({
                    session_id: @session_id,
                    shotID: @ship.shotsFired,
                    position: @ship.position.clone(),
                    velocity: newDir.transformDirection(m2),
                    rotation: @controls.targetObject.quaternion
                })
                bullet.connection.on 'bullet_create', (data) =>
                    if not bullet.id
                        bullet.id = data.id
                        @bullets.add(bullet)
                bullet.save()
                bullet.mesh.applyMatrix(m2)
                bullet.mesh.rotateOnAxis(new THREE.Vector3(1,0,0),Math.PI/2)
                @scene.add bullet.mesh

            when 'missile'
                missile = new Missile({
                    position:@ship.position.clone(),
                    velocity:@ship.rotationV.clone().multiplyScalar(500)
                })
                m2 = new THREE.Matrix4()
                m2.makeRotationY(-Math.PI/2)
                m2.multiplyMatrices(m2,@controls.targetObject.matrix)
                m2.multiplyScalar(0.2)
                missile.mesh.applyMatrix(m2)
                @missiles.add(missile)
                @scene.add missile.mesh

    tickrate: 500
    lastUpdate: 0

    gameloop: =>

        # use requestAnimationFrame to loop animation
        animate = ->
            requestAnimationFrame(animate)
            update()
            render()

        # update game objects
        update = =>

            delta = @clock.getDelta()
            @chasecamera.update(delta)
            @controls.update(delta)

            if @controls.moveState.boost
                @effectSave.enabled = true
                @effectBlend.enabled = true
            else
                @effectSave.enabled = false
                @effectBlend.enabled = false

            if @controls.aimMode
                @lockOnTarget(@controls.cursor_x,@controls.cursor_y)

            @players.fetch() # Active Players
            @bullets.fetch()

            # Projectiles
            if @controls.fireStandard
                if +new Date() - @lastFireStandard > 1000
                    @lastFireStandard = +new Date()
                    @fire("standard")

            if @controls.fireMissile
                if +new Date() - @lastFireMissile > 5000
                    @lastFireMissile = +new Date()
                    @fire("missile")
            
            #@ship.particleCloud.geometry.verticesNeedUpdate = true
            #@ship.attributes.size.needsUpdate = true
            #@ship.attributes.pcolor.needsUpdate = true

            @ship.save()

            @cannonWorld.step(delta)
            return

        # call renderer
        render = =>
            @renderer.setViewport(0, 0, window.innerWidth, window.innerHeight)
            @renderer.clear()
            @renderer.initWebGLObjects( @scene )
            @composer.render( 0.1 )
            
            # Render Cursor
            
            @context.save()
            @context.clearRect(0,0,window.innerWidth,window.innerHeight)
            @context.translate(@controls.cursor_x, @controls.cursor_y)
            if (@controls.aimMode)
                @context.drawImage(SpaceBees.Loader.get('images','aim'),0,0)
            else
                @context.rotate(Math.atan2((@controls.cursor_y-window.innerHeight/2),(@controls.cursor_x-window.innerWidth/2)))
                @context.drawImage(SpaceBees.Loader.get('images','cursor'),0,0)
            @context.restore()

            if (@target_id?)
                pos = @pickingObjects[0].position.clone()
                @projector.projectVector(pos,@camera)
                @context.drawImage(SpaceBees.Loader.get('images','target_lock'),pos.x * window.innerWidth/2 + window.innerWidth/2,pos.y  * -window.innerHeight/2 + window.innerHeight/2)


        animate()
        return
