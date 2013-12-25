module.exports = class MissileModel extends Backbone.Model

    initialize : =>
        @startTime = +new Date()
        @socket = @get("socket")
        @startPos = @get("position").clone()
        @maxDist = @get("maxDist") or 1000
        @position = @startPos.clone()
        @velocity = @get("velocity")
        missileMesh = new THREE.Mesh(SpaceBees.Loader.get('geometries','missile'), new THREE.MeshNormalMaterial())

        #console.log new THREE.Vector3().subVectors(@position, @startPos).length()

        # create the particle variables
        ###
        particleCount = 1800
        particles = new THREE.Geometry
        pMaterial = new THREE.ParticleBasicMaterial { color: 0xFFFFFF, size: 20, map: SpaceBees.Loader.get('textures','missile_particle'), blending: THREE.AdditiveBlending, transparent: true}

        # now create the individual particles
        for p in [1..particleCount]
            particle = new THREE.Vertex(@position)
            # add it to the geometry
            particles.vertices.push(particle)

        # create the particle system
        @particleSystem = new THREE.ParticleSystem(particles, pMaterial)
        @particleSystem.sortParticles = true

        @mesh = new THREE.Object3D()
        @mesh.add(missileMesh)
        ###
        #@mesh.add(particleSystem)
        @mesh.position = @position
        return

    update : =>
        t = (+new Date()-@startTime)/1000 # in sec
        @position.copy(@startPos).add(@velocity.clone().multiplyScalar(t))
        @particleSystem.rotation.y += 0.01

    loadModel : ->

    sync : (method, model, options) ->
        
