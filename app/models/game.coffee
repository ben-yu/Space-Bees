Ship = require 'models/ship'
Missile = require 'models/missile'
LockedControls = require 'lib/lockedcontrols'
ChaseCamera = require 'lib/chasecamera'

module.exports = class Game extends Backbone.Model
    defaults:
        width: 800
        length: 600
    geometries:
        'missile' : 'geometries/missiles/hellfire.js'

    textures:
        'missile' : 'textures/missiles/hellfire_skin.png'

    skyCubes:
        interstellar : ["textures/skybox/interstellar/px.jpg","textures/skybox/interstellar/nx.jpg",
                        "textures/skybox/interstellar/py.jpg","textures/skybox/interstellar/ny.jpg",
                        "textures/skybox/interstellar/pz.jpg","textures/skybox/interstellar/nz.jpg"]

    initialize: ->
        container = $('#game')

        @lastFireMissile = +new Date()

        @clock = new THREE.Clock()
        @objects = []

        blocker = document.getElementById 'blocker'
        instructions = document.getElementById 'instructions'

        # set the scene size
        WIDTH = window.innerWidth
        HEIGHT = window.innerHeight

        # set some camera attributes
        VIEW_ANGLE = 45
        ASPECT = WIDTH / HEIGHT
        NEAR = 0.1
        FAR = 10000

        @renderer = new THREE.WebGLRenderer

        @camera = new THREE.PerspectiveCamera VIEW_ANGLE, ASPECT, NEAR, FAR
        @scene = new THREE.Scene

        #@scene.fog = new THREE.Fog( 0xcce0ff, 500, 10000 )

        # Skybox

        skyshader = THREE.ShaderLib["cube"]
        skyshader.uniforms[ "tCube" ].value  = THREE.ImageUtils.loadTextureCube(@skyCubes.interstellar)

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

        groundTexture = THREE.ImageUtils.loadTexture "textures/terrain/chipmetal/texturemap.jpg", undefined, () ->
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

        # Players
        @players = new Backbone.Collection()
        @ship = new Ship()
        @camera.position.z = 300
        console.log @ship.mesh

        @controls = new LockedControls @ship.mesh

        @chasecamera = new ChaseCamera @camera, @ship.mesh

        @scene.add @ship.mesh
        @scene.add @camera

        # Projectiles
        @missiles = new Backbone.Collection()

        # Lighting
        ambient = 0x222222
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
        @renderer.autoClear = false

        # Pointer Lock - http://www.html5rocks.com/en/tutorials/pointerlock/intro/

        havePointerLock = 'pointerLockElement' of document or
            'mozPointerLockElement' of document or
            'webkitPointerLockElement' of document

        if havePointerLock

            element = document.body

            pointerlockchange =  ( event ) =>

                if document.pointerLockElement is element or document.mozPointerLockElement is element or document.webkitPointerLockElement is element

                    @controls.enabled = true
                    blocker.style.display = 'none'
            
                else

                    @controls.enabled = false
                    blocker.style.display = '-webkit-box'
                    blocker.style.display = '-moz-box'
                    blocker.style.display = 'box'

                    instructions.style.display = ''

            pointerlockerror =  ( event ) =>
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
                element.requestPointerLock = element.requestPointerLock or element.mozRequestPointerLock or element.webkitRequestPointerLock;

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
        #@renderer.render(@scene, @camera)
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
        @missiles.add(missile)
        #console.log missile.mesh.position
        @scene.add missile.mesh
        #console.log 'fire!'


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

            @missiles.forEach (bullet) =>
                bullet.update()

            if @controls.fireMissile
                if +new Date() - @lastFireMissile > 500
                    @lastFireMissile = +new Date()
                    @fire("missile")
            

            # Collision
            @ray.ray.origin.copy( @controls.getObject().position )
            @ray.ray.origin.y -= 10

            intersections = @ray.intersectObjects(@objects)

            if intersections.length > 0
                distance = intersections[0].distance
                if distance > 0 and distance < 10
                    @controls.collision(true)

            @ship.position.copy(@controls.targetObject.position)
            forward = new THREE.Vector3(0,0,-1)
            @ship.rotationV.copy(forward.transformDirection(@controls.targetObject.matrix))


            return

        # call renderer
        render = =>
            @renderer.render @scene, @camera

        animate()
        return
