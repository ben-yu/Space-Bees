module.exports = class MapGenerator
    constructor: () ->

    createMap:(scene,cannonWorld,renderer,buildingData) ->
        scene.fog = new THREE.Fog( 0xffffff, 3000, 100000 )
        scene.fog.color.setHSL( 0.51, 0.6, 0.6 )
        @createSkyBox(scene)
        @generateCityTerrain(scene,cannonWorld,renderer,buildingData)

    createSkyBox: (scene) ->
        skyshader = THREE.ShaderLib["cube"]
        skyshader.uniforms["tCube"].value  = SpaceBees.Loader.get('texturesCube','interstellar')

        skymaterial = new THREE.ShaderMaterial({
            fragmentShader : skyshader.fragmentShader,
            vertexShader : skyshader.vertexShader,
            uniforms : skyshader.uniforms,
            depthWrite: false,
            side: THREE.BackSide
        })

        skybox = new THREE.Mesh( new THREE.CubeGeometry(200000, 200000, 200000), skymaterial )
        scene.add skybox

    generateTexture: ->
        canvas  = document.createElement( 'canvas' )
        canvas.width = 32
        canvas.height = 64
        context = canvas.getContext('2d')

        #paint it in white
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

    generateCityTerrain: (scene, cannonWorld, renderer, buildingData) =>

        # generate building texture
        texture = new THREE.Texture(@generateTexture())
        texture.wrapS = texture.wrapT = THREE.RepeatWrapping
        texture.repeat.set(5, 5)
        texture.anisotropy = renderer.getMaxAnisotropy()

        texture.needsUpdate = true

        # build the mesh
        material  = new THREE.MeshLambertMaterial({
            map : texture,
            vertexColors : THREE.VertexColors
        })
        
        light = new THREE.Color( 0xffffff )
        shadow    = new THREE.Color( 0x000000)
        
        buildings = new THREE.Object3D()
        physicsMaterial = new CANNON.Material "slipperyMaterial"
        for i in buildingData
            # set .vertexColors for each face
            geometry = new THREE.CubeGeometry i.w,i.h,i.w
            cannonBox =  new CANNON.RigidBody(-1,new CANNON.Box(new CANNON.Vec3(i.w/2,i.h/2,i.w/2)))
            for j in [0..geometry.faces.length-1]
                value    = 1 - Math.random() * Math.random()
                baseColor   = new THREE.Color().setRGB( value + Math.random() * 0.1, value, value + Math.random() * 0.1 )
                # set topColor/bottom vertexColors as adjustement of baseColor
                topColor    = baseColor.clone().multiply( light )
                bottomColor = baseColor.clone().multiply( shadow )
                if j == 3
                    # set face.vertexColors on root face
                    geometry.faces[ j ].vertexColors = [ shadow, shadow, shadow, shadow ]
                else
                    # set face.vertexColors on sides faces
                    geometry.faces[ j ].vertexColors = [ topColor, bottomColor, bottomColor, topColor ]
            city = new THREE.Mesh(geometry, material)
            city.useQuaternion  = true
            cannonBox.position.set(i.x,250,i.z)
            city.position.set(i.x,250,i.z)
            buildings.add(city)
            #console.log cannonBox
            cannonWorld.add cannonBox
        scene.add buildings

        # Create the floor
        initColor = new THREE.Color( 0x497f13 )
        initTexture = THREE.ImageUtils.generateDataTexture( 1, 1, initColor )

        groundMaterial = new THREE.MeshPhongMaterial { color: 0xffffff, specular: 0x111111, map: initTexture }

        groundTexture = SpaceBees.Loader.get('textures','chipmetal')
        groundMaterial.map = groundTexture
        groundTexture.wrapS = groundTexture.wrapT = THREE.RepeatWrapping
        groundTexture.repeat.set( 25, 25 )
        groundTexture.anisotropy = 16

        floor = new THREE.Mesh( new THREE.PlaneGeometry( 200000, 200000 ), groundMaterial )
        floor.position.y = -250
        floor.rotation.x = - Math.PI / 2
        floor.receiveShadow = true


        groundShape = new CANNON.Plane()
        groundBody = new CANNON.RigidBody(0,groundShape,physicsMaterial)
        groundBody.quaternion.setFromAxisAngle(new CANNON.Vec3(1,0,0),-Math.PI/2)
        groundBody.position.y = -250
        cannonWorld.add(groundBody)

        scene.add floor