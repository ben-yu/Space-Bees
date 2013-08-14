#Ship = require 'models/ship'
ActivePlayers = require 'collections/activeplayers'
Bee = require 'models/bee'
Ship = require 'models/ship'
Missile = require 'models/missile'
Bullet = require 'models/bullet'
Bullets = require 'collections/bullets'
LockedControls = require 'lib/lockedcontrols'
ChaseCamera = require 'lib/chasecamera'

module.exports = class Game extends Backbone.Model
    tickrate: 300

    initialize: ->

    start: =>
        container = $('#game')

        @lastFireStandard = +new Date()
        @lastFireMissile = +new Date()

        @clock = new THREE.Clock()
        @objects = []
        @pickingObjects = []
        @materials = {}

        WIDTH = window.innerWidth
        HEIGHT = window.innerHeight

        blocker = document.getElementById 'blocker'
        instructions = document.getElementById 'instructions'

        cursorOverlay = document.getElementById('cursorOverlay')
        cursorOverlay.width = WIDTH
        cursorOverlay.height = HEIGHT
        cursorOverlay.style.width = WIDTH
        cursorOverlay.style.height = HEIGHT
        cursorOverlay.style.top = 0
        cursorOverlay.style.left = 0
        cursorOverlay.style.position = 'absolute'
        @context = cursorOverlay.getContext('2d')

        # set some camera attributes
        VIEW_ANGLE = 45
        ASPECT = WIDTH / HEIGHT
        NEAR = 0.1
        FAR = 100000

        @camera = new THREE.PerspectiveCamera VIEW_ANGLE, ASPECT, NEAR, FAR
        @projector = new THREE.Projector()

        @scene = new THREE.Scene
        @scene.fog = new THREE.Fog( 0xffffff, 3000, 10000 )
        @scene.fog.color.setHSL( 0.51, 0.6, 0.6 )

        @pickingScene = new THREE.Scene
        @pickingTexture = new THREE.WebGLRenderTarget( window.innerWidth, window.innerHeight )
        @pickingTexture.generateMipmaps = false

        @renderer = new THREE.WebGLRenderer { antialias: false }
        @renderer.setClearColor( @scene.fog.color, 1 )

        @pickRenderer = new THREE.WebGLRenderer( { antialias: true } )
        @pickRenderer.setClearColor(0xffffff)
        @pickRenderer.sortObjects = false
        @pickRenderer.setSize( window.innerWidth, window.innerHeight )

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

        # Terrain Generation

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

        @generateTerrain()
        ###
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
        ###

        # Players

        @ship = new Ship({id:window.socket.socket.sessionid})
        @camera.position.z = 300

        @players = new ActivePlayers([],{parentScene:@scene, selfId:window.socket.socket.sessionid})
        @players.fetch()

        @enemies = new Backbone.Collection()
        #@enemy = new Bee()
        #@scene.add @enemy.mesh
        #@addToPicking @enemy

        @controls = new LockedControls @ship.mesh

        @chasecamera = new ChaseCamera @camera, @ship.mesh

        @scene.add @ship.mesh
        @scene.add @camera

        # Projectiles
        @bullets = new Bullets([],{parentScene:@scene, selfId:window.socket.socket.sessionid})
        @bullets.fetch()
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
        @intersectDirections = [new THREE.Vector3(0,-1,0),
                                new THREE.Vector3(0,1,0),
                                new THREE.Vector3(-1,0,0),
                                new THREE.Vector3(1,0,0),
                                new THREE.Vector3(0,0,-1),
                                new THREE.Vector3(0,0,1)]

        @renderer.setSize WIDTH, HEIGHT

        # POSTPROCESSING
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
        #renderModel.clear = false

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

        # Pointer Lock - http://www.html5rocks.com/en/tutorials/pointerlock/intro/

        havePointerLock = 'pointerLockElement' of document or
            'mozPointerLockElement' of document or
            'webkitPointerLockElement' of document

        if havePointerLock

            element = document.body

            pointerlockchange =  (event) =>

                if document.pointerLockElement is element or document.mozPointerLockElement is element or document.webkitPointerLockElement is element

                    @controls.enabled = true
                    @controls.cursor_x = WIDTH/2
                    @controls.cursor_y = HEIGHT/2
                    blocker.style.display = 'none'
                    cursorOverlay.style.display = true
            
                else

                    @controls.enabled = false
                    blocker.style.display = '-webkit-box'
                    blocker.style.display = '-moz-box'
                    blocker.style.display = 'box'
                    cursorOverlay.style.display = false

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

            instructions.addEventListener( 'click',  (event) =>

                instructions.style.display = 'none'
                cursorOverlay.style.display = false

                # Ask the browser to lock the pointer
                element.requestPointerLock = element.requestPointerLock or element.mozRequestPointerLock or element.webkitRequestPointerLock

                if ( /Firefox/i.test(navigator.userAgent))

                    fullscreenchange =  (event) =>

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

        @gameloop()

        return

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

    lockOnTarget: (x,y) =>
        @target_id = @pickObject(x,y)

    applyVertexColors: (geom, color) =>

        for f in geom.faces
            for vertexColor in f.vertexColors
                vertexColor = color

    generateTexture: =>
        canvas  = document.createElement( 'canvas' )
        canvas.width = 32
        canvas.height = 64
        context = canvas.getContext('2d')

        #plain it in white
        context.fillStyle  = '#ffffff'
        context.fillRect(0, 0, 32, 64)
        # draw the window rows - with a small noise to simulate light variations in each room
        for y in [2...64] by 2
            for x in [0...32] by 2
                value   = Math.floor( Math.random() * 64 )
                context.fillStyle = 'rgb(' + [value, value, value].join(',')  + ')'
                context.fillRect( x, y, 2, 1 )

        # build a bigger canvas and copy the small one in it
        # This is a trick to upscale the texture without filtering
        canvas2 = document.createElement('canvas')
        canvas2.width  = 512
        canvas2.height = 1024
        context = canvas2.getContext('2d')

        # disable smoothing
        context.imageSmoothingEnabled = false
        context.webkitImageSmoothingEnabled  = false
        context.mozImageSmoothingEnabled = false

        # then draw the image
        context.drawImage( canvas, 0, 0, canvas2.width, canvas2.height )
        return canvas2

    generateTerrain: =>

        geometry = new THREE.CubeGeometry(1,1,1)

        # move pivot
        geometry.applyMatrix(new THREE.Matrix4().makeTranslation(0,0.5,0))
        geometry.faces.splice(3,1); # remove bottom face
        geometry.faceVertexUvs[0][2][0].set( 0, 0 )
        geometry.faceVertexUvs[0][2][1].set( 0, 0 )
        geometry.faceVertexUvs[0][2][2].set( 0, 0 )
        geometry.faceVertexUvs[0][2][3].set( 0, 0 )

        buildingMesh = new THREE.Mesh(geometry)

        # base colors for vertexColors. light is for vertices at the top, shaddow is for the ones at the bottom
        light = new THREE.Color( 0xffffff )
        shadow = new THREE.Color( 0x303050 )

        cityGeometry = new THREE.Geometry()

        for i in [0...20000]
            # put a random position
            buildingMesh.position.x   = Math.floor( Math.random() * 200 - 100 ) * 10
            buildingMesh.position.z   = Math.floor( Math.random() * 200 - 100 ) * 10
            # put a random rotation
            buildingMesh.rotation.y   = Math.random()*Math.PI*2
            # put a random scale
            buildingMesh.scale.x  = Math.random() * Math.random() * Math.random() * Math.random() * 50 + 10
            buildingMesh.scale.y  = (Math.random() * Math.random() * Math.random() * buildingMesh.scale.x) * 8 + 8
            buildingMesh.scale.z  = buildingMesh.scale.x

            # establish the base color for the buildingMesh
            value   = 1 - Math.random() * Math.random()
            baseColor   = new THREE.Color().setRGB( value + Math.random() * 0.1, value, value + Math.random() * 0.1 )
            # set topColor/bottom vertexColors as adjustement of baseColor
            topColor    = baseColor.clone().multiply( light )
            bottomColor = baseColor.clone().multiply( shadow )
            # set .vertexColors for each face
            geometry  = buildingMesh.geometry
            jl = geometry.faces.length
            for j in [0...jl]
                if ( j == 2 )
                    # set face.vertexColors on root face
                    geometry.faces[ j ].vertexColors = [ baseColor, baseColor, baseColor, baseColor ]
                else
                    # set face.vertexColors on sides faces
                    geometry.faces[ j ].vertexColors = [ topColor, bottomColor, bottomColor, topColor ]
            # merge it with cityGeometry - very important for performance
            THREE.GeometryUtils.merge( cityGeometry, buildingMesh )

        # generate the texture
        texture = new THREE.Texture(@generateTexture())
        texture.anisotropy = @renderer.getMaxAnisotropy()
        texture.needsUpdate = true

        # build the mesh
        material  = new THREE.MeshLambertMaterial({
            map : texture,
            vertexColors : THREE.VertexColors
        })
        
        cityMesh = new THREE.Mesh(cityGeometry, material)

        cityMesh.scale.set(15.0,15.0,15.0)
        cityMesh.position.y = -250

        @scene.add cityMesh

    fire: (type) =>
        switch type
            when 'standard'
                @ship.shotsFired += 1
                bullet = new Bullet({
                    shotID:@ship.shotsFired,
                    position:@ship.position.clone(),
                    velocity:@ship.rotationV.clone().multiplyScalar(500)
                })
                m2 = new THREE.Matrix4()
                m2.makeRotationY(-Math.PI/2)
                m2.multiplyMatrices(m2,@controls.targetObject.matrix)
                m2.multiplyScalar(0.2)
                bullet.mesh.applyMatrix(m2)
                @bullets.add(bullet)
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

            if @controls.moveState.boost
                @effectSave.enabled = true
                @effectBlend.enabled = true
            else
                @effectSave.enabled = false
                @effectBlend.enabled = false

            if @controls.aimMode
                @lockOnTarget(@controls.cursor_x,@controls.cursor_y)


            # Active Players
            @players.fetch()
            @bullets.fetch()

            # Projectiles
            if @controls.fireStandard
                if +new Date() - @lastFireStandard > 100
                    @lastFireStandard = +new Date()
                    @fire("standard")

            if @controls.fireMissile
                if +new Date() - @lastFireMissile > 500
                    @lastFireMissile = +new Date()
                    @fire("missile")

            @bullets.forEach (bullet) =>
                #bullet.update()
                bullet.save(null,{
                    success: (model, response) =>
                        console.log "success"
                    error: (model, response) =>
                        console.log "error"
                })
                if (new THREE.Vector3().subVectors(bullet.startPos, bullet.position).length()> bullet.maxDist)
                    @scene.remove(bullet.mesh)
                    bullet.destroy()


            @missiles.forEach (bullet) =>
                bullet.update()
                if (new THREE.Vector3().subVectors(bullet.startPos, bullet.position).length()> bullet.maxDist)
                    @scene.remove(bullet.mesh)
                    bullet.destroy()
            
            # Collision
            @ray.ray.origin.copy @controls.getObject().position
            @ray.ray.origin.y -= 10

            for dir in @intersectDirections

                @ray.ray.direction.copy(dir)

                intersections = @ray.intersectObjects(@objects)

                if intersections.length > 0
                    for intersection in intersections
                        distance = intersection.distance
                        if distance > 0 and distance < 10
                            @controls.collision(true)
                            console.log 'collision!'

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
