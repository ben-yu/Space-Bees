#Ship = require 'models/ship'
ActivePlayers = require 'models/activeplayers'
Ship = require 'models/ship'
Missile = require 'models/missile'
LockedControls = require 'lib/lockedcontrols'
ChaseCamera = require 'lib/chasecamera'

module.exports = class Game extends Backbone.Model
    tickrate: 300
    defaults:
        width: 800
        length: 600

    initialize: ->

    start: =>
        container = $('#game')

        @lastFireMissile = +new Date()

        @clock = new THREE.Clock()
        @objects = []

        @materials = {}

        blocker = document.getElementById 'blocker'
        instructions = document.getElementById 'instructions'

        # set the scene size
        WIDTH = window.innerWidth
        HEIGHT = window.innerHeight

        # set some camera attributes
        VIEW_ANGLE = 45
        ASPECT = WIDTH / HEIGHT
        NEAR = 0.1
        FAR = 100000

        @camera = new THREE.PerspectiveCamera VIEW_ANGLE, ASPECT, NEAR, FAR
        @scene = new THREE.Scene
        @scene.fog = new THREE.Fog( 0xffffff, 3000, 10000 )
        @scene.fog.color.setHSL( 0.51, 0.6, 0.6 )


        @renderer = new THREE.WebGLRenderer { antialias: false }
        @renderer.setClearColor( @scene.fog.color, 1 )

        # Skybox

        skyshader = THREE.ShaderLib["cube"]
        skyshader.uniforms["tCube"].value  = SpaceBees.Loader.get('texturesCube','interstellar')

        skymaterial = new THREE.ShaderMaterial({
            fragmentShader : skyshader.fragmentShader,
            vertexShader : skyshader.vertexShader,
            uniforms : skyshader.uniforms,
            depthWrite: false,
            side: THREE.BackSide
        })

        skybox = new THREE.Mesh( new THREE.CubeGeometry(20000, 20000, 20000), skymaterial )
        @scene.add skybox

        # Terrain

        initColor = new THREE.Color( 0x497f13 )
        initTexture = THREE.ImageUtils.generateDataTexture( 1, 1, initColor )

        groundMaterial = new THREE.MeshPhongMaterial { color: 0xffffff, specular: 0x111111, map: initTexture }

        groundTexture = SpaceBees.Loader.get('textures','chipmetal')
        groundMaterial.map = groundTexture
        groundTexture.wrapS = groundTexture.wrapT = THREE.RepeatWrapping
        groundTexture.repeat.set( 25, 25 )
        groundTexture.anisotropy = 16

        floor = new THREE.Mesh( new THREE.PlaneGeometry( 20000, 20000 ), groundMaterial )
        floor.position.y = -250
        floor.rotation.x = - Math.PI / 2
        floor.receiveShadow = true
        @scene.add floor
        @objects.push floor

        @materials.scrapers1 = new THREE.MeshBasicMaterial({
            map: SpaceBees.Loader.get("textures", "scrapers1.diffuse"),
            ambient: 0xcccccc
        })

        @materials.scrapers2 = new THREE.MeshBasicMaterial({
            map: SpaceBees.Loader.get("textures", "scrapers2.diffuse"),
            ambient: 0xcccccc
        })

        for i in [0..2]
            for j in [0..2]
                if i+j%2 == 0
                    building = new THREE.Mesh( SpaceBees.Loader.get('geometries','scrapers1'), @materials.scrapers1 )
                else
                    building = new THREE.Mesh( SpaceBees.Loader.get('geometries','scrapers2'), @materials.scrapers2 )
                building.position.set( 5000*i - 5000, 250, 5000*j - 5000)
                @scene.add building
                @objects.push building

        # Players

        @ship = new Ship({id:window.socket.socket.sessionid})
        @camera.position.z = 300

        @players = new ActivePlayers([],{parentScene:@scene, selfId:window.socket.socket.sessionid})
        @players.fetch()

        @controls = new LockedControls @ship.mesh

        @chasecamera = new ChaseCamera @camera, @ship.mesh

        @scene.add @ship.mesh
        @scene.add @camera

        # Projectiles
        @missiles = new Backbone.Collection()

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

        @ray = new THREE.Raycaster()
        @ray.ray.direction.set(0,-1,0)

        @renderer.setSize WIDTH, HEIGHT

        # POSTPROCESSING
        @renderer.autoClear = false

        renderTargetParameters = { minFilter: THREE.LinearFilter, magFilter: THREE.LinearFilter, format: THREE.RGBFormat, stencilBuffer: false }
        renderTarget = new THREE.WebGLRenderTarget WIDTH, HEIGHT, renderTargetParameters

        effectSave = new THREE.SavePass( new THREE.WebGLRenderTarget( WIDTH, HEIGHT, renderTargetParameters ) )
        effectBlend = new THREE.ShaderPass( THREE.BlendShader, "tDiffuse1" )

        # Motion Blur

        effectBlend.uniforms[ 'tDiffuse2' ].value = effectSave.renderTarget
        effectBlend.uniforms[ 'mixRatio' ].value = 0.65

        renderModel = new THREE.RenderPass( @scene, @camera )
        #renderModel.clear = false

        effectBlend.renderToScreen = true

        @composer = new THREE.EffectComposer( @renderer, renderTarget )
        @composer.addPass( renderModel )

        @composer.addPass( effectBlend )
        #@composer.addPass( effectSave )

        effectSave.enabled = true
        effectBlend.enabled = true

        # Pointer Lock - http://www.html5rocks.com/en/tutorials/pointerlock/intro/

        havePointerLock = 'pointerLockElement' of document or
            'mozPointerLockElement' of document or
            'webkitPointerLockElement' of document

        if havePointerLock

            element = document.body

            pointerlockchange =  (event) =>

                if document.pointerLockElement is element or document.mozPointerLockElement is element or document.webkitPointerLockElement is element

                    @controls.enabled = true
                    blocker.style.display = 'none'
            
                else

                    @controls.enabled = false
                    blocker.style.display = '-webkit-box'
                    blocker.style.display = '-moz-box'
                    blocker.style.display = 'box'

                    instructions.style.display = ''

            pointerlockerror =  (event) =>
                instructions.style.display = ''

            # Hook pointer lock state change events
            document.addEventListener 'pointerlockchange', pointerlockchange, false
            document.addEventListener 'mozpointerlockchange', pointerlockchange, false
            document.addEventListener 'webkitpointerlockchange', pointerlockchange, false

            document.addEventListener 'pointerlockerror', pointerlockerror, false
            document.addEventListener 'mozpointerlockerror', pointerlockerror, false
            document.addEventListener 'webkitpointerlockerror', pointerlockerror, false

            instructions.addEventListener( 'click',  (event) ->

                instructions.style.display = 'none'

                # Ask the browser to lock the pointer
                element.requestPointerLock = element.requestPointerLock or element.mozRequestPointerLock or element.webkitRequestPointerLock

                if ( /Firefox/i.test( navigator.userAgent ) )

                    fullscreenchange =  (event) ->

                        if (document.fullscreenElement is element or document.mozFullscreenElement is element or document.mozFullScreenElement is element)
                            document.removeEventListener( 'fullscreenchange', fullscreenchange )
                            document.removeEventListener( 'mozfullscreenchange', fullscreenchange )

                        element.requestPointerLock()

                    document.addEventListener( 'fullscreenchange', fullscreenchange, false )
                    document.addEventListener( 'mozfullscreenchange', fullscreenchange, false )

                    element.requestFullscreen = element.requestFullscreen or element.mozRequestFullscreen or element.mozRequestFullScreen or element.webkitRequestFullscreen
                    element.requestFullscreen()

                else
                    element.requestPointerLock()

            , false)

        else
            instructions.innerHTML = 'Your browser doesn\'t seem to support Pointer Lock API'

        container.prepend(@renderer.domElement)

        bg_sound = new Howl({
            urls: ['sounds/background/8_bit.mp3'],
            loop: true
        })

        #bg_sound.play()

        @gameloop()

        return

    addPlayer: (player) =>
        @players.add(player)
        @scene.add(player.mesh)

    load: =>


    loadMap: =>

    fire: (type) =>
        missile = new Missile({
            position:@ship.position.clone(),
            velocity:@ship.rotationV.clone().multiplyScalar(500)
        })
        m2 = new THREE.Matrix4()
        m2.makeRotationY(-Math.PI/2)
        m2.multiplyMatrices(m2,@controls.targetObject.matrix)
        m2.multiplyScalar(0.2)
        missile.mesh.applyMatrix(m2)
        console.log @ship.rotationV
        @missiles.add(missile)
        @scene.add missile.mesh

    gameloop: =>

        # use requestAnimationFrame to loop animation
        animate = =>
            requestAnimationFrame(animate)
            update()
            render()

        # update game objects
        update = =>

            delta = @clock.getDelta()
            @chasecamera.update(delta)
            @controls.update(delta)

            # Active Players
            @players.fetch()

            # Projectiles

            @missiles.forEach (bullet) =>
                bullet.update()
                if (new THREE.Vector3().subVectors(bullet.startPos, bullet.position).length()> bullet.maxDist)
                    @scene.remove(bullet.mesh)
                    bullet.destroy()

            if @controls.fireMissile
                if +new Date() - @lastFireMissile > 500
                    @lastFireMissile = +new Date()
                    @fire("missile")
            
            # Collision
            @ray.ray.origin.copy @controls.getObject().position
            @ray.ray.origin.y -= 10

            intersections = @ray.intersectObjects(@objects)

            if intersections.length > 0
                distance = intersections[0].distance
                if distance > 0 and distance < 10
                    @controls.collision(true)

            @ship.position.copy(@controls.targetObject.position)
            forward = new THREE.Vector3(0,0,-1)
            @ship.rotationV.copy(forward.transformDirection(@controls.targetObject.matrix))

            @ship.save(null,{
                success: (model, response) =>
                    #console.log "success"
                error: (model, response) =>
                    #console.log "error"
            })


            return

        # call renderer
        render = =>
            @renderer.setViewport(0, 0, window.innerWidth, window.innerHeight)
            #@renderer.clear()
            @renderer.initWebGLObjects( @scene )
            @composer.render( 0.1 )

        animate()
        return
