Bullet = require 'models/bullet'

module.exports = class Bullets extends Backbone.Collection
    model: Bullet

    initialize: (models, options) ->
        @connection = window.socket
        @parentScene = options.parentScene
        @selfId = options.selfId

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
            #console.log method
            switch method
                when 'create' then
                when 'read'
                    for k,v of data
                        if @get(k)?
                            bullet = @get(k)
                            bullet.mesh.position.copy(v.pos)
                            bullet.mesh.rotation.copy(v.dir)
                        else if v.playerID isnt @selfId
                            #console.log v.playerID + ":" + @selfId
                            pos = new THREE.Vector3(v.pos.x,v.pos.y,v.pos.z)
                            bullet = new Bullet({id:k,playerID:v.playerID,shotID:v.shotID,position:pos})
                            @add(bullet)
                            @parentScene.add(bullet.mesh)
                when 'update'
                    for k,v of data
                        if @get(k)?
                            bullet = @get(k)
                            bullet.mesh.position.copy(v.pos)
                            bullet.mesh.rotation.copy(v.dir)
                        else if v.playerID isnt @selfId
                            pos = new THREE.Vector3(v.pos.x,v.pos.y,v.pos.z)
                            bullet = new Bullet({playerID:v.playerID,shotID:v.shotID,position:pos})
                            @add(bullet)
                            @parentScene.add(bullet.mesh)
                when 'delete'
                    if @get(data)
                        @parentScene.remove(@get(data).mesh)
                        @remove(@get(data))