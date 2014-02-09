Bullet = require 'models/bullet'

module.exports = class Bullets extends Backbone.Collection
    model: Bullet

    initialize: (models, options) ->
        @connection = window.socket
        @parentScene = options.parentScene
        @selfId = options.selfId

        @flag = 1

        @connection.on 'bullets_delete', (data) =>
            if @get(data)
                @parentScene.remove(@get(data).mesh)
                @remove(@get(data))

    getState: () =>
        state = []
        for m in @models
            state.push m.getState()
        return state

    sync: (method, model, options) =>
        options.data ?= {}
        @connection.emit 'bullets_' + method, model.getState(), options.data, (err, data) ->
            if err
                console.error "error in sync with #{method} #{@.name()} with server (#{err})"
            else
                options.success data

        @connection.on 'bullets_' + method, (data) =>
            switch method
                when 'create' then
                when 'read'
                    for v in data
                        #console.log @get(v.id)?
                        if @get(v.id)?
                            # update bullet pos and rot
                            bullet = @get(v.id)
                            bullet.mesh.position.copy(v.pos)
                            #bullet.mesh.rotation.copy(v.dir)
                        else if v.playerID isnt @selfId
                            # Create a new bullet
                            m2 = new THREE.Matrix4()
                            m2.makeRotationY(-Math.PI)
                            newDir = new THREE.Vector3(0,1,0)
                            pos = new THREE.Vector3(v.pos.x,v.pos.y,v.pos.z)
                            bullet = new Bullet({id:v.id,playerID:v.playerID,shotID:v.shotID,position:pos,velocity:v.dir})
                            @add(bullet)
                            @parentScene.add(bullet.mesh)
                when 'update'
                    for v in data
                        if @get(v.id)?
                            bullet = @get(v.id)
                            bullet.mesh.position.copy(v.pos)
                            #bullet.mesh.rotation.copy(v.dir)
                        else if v.playerID isnt @selfId
                            m2 = new THREE.Matrix4()
                            m2.makeRotationX(-Math.PI/2)
                            newDir = new THREE.Vector3(0,1,0)
                            pos = new THREE.Vector3(v.pos.x,v.pos.y,v.pos.z)
                            bullet = new Bullet({id:v.id,playerID:v.playerID,shotID:v.shotID,position:pos})
                            @add(bullet)
                            @parentScene.add(bullet.mesh)
                when 'delete'
                    for v in data
                        if @get(v.id)?
                            bullet = @get(v.id)
                            @parentScene.remove(bullet.mesh)
                            @remove(bullet)