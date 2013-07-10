module.exports = class MissileModel extends Backbone.Model

    initialize : =>
        @startTime = +new Date()
        @startPos = @get("position") or new THREE.Vector3(0,0,0)
        @maxDist = @get("maxDist") or 50000
        @position = @startPos.clone()
        @velocity = @get("velocity")
        #console.log @velocity
        @mesh = new THREE.Mesh(new THREE.SphereGeometry(2), new THREE.MeshNormalMaterial())
        @mesh.position = @position

        return

    update : =>
        d = new THREE.Vector3().subVectors(@position, @startPos).length()
        t = (+new Date()-@startTime)/1000 # in sec
        @position.copy(@startPos).add(@velocity.clone().multiplyScalar(t))
        #@mesh.position.copy(@position)
        if (d>@maxDist)
            @destroy()

    loadModel : =>

    sync : (method, model, options) =>
        
        switch method
            when "create"
                console.log 'create'
            when "read" then
            when "update" then
            when "delete" then
