Ship = require 'models/ship'

module.exports = class ActivePlayers extends Backbone.Collection
    model: Ship

    initialize: (models, options) ->
        @connection = window.socket
        @parentScene = options.parentScene
        @selfId = options.selfId

        @connection.on 'players_delete', (data) =>
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
        if method is 'create'
            console.log 'New Player'

        @connection.emit 'players_' + method, model.getState(), options.data, (err, data) ->
            if err
                console.error "error in sync with #{method} #{@.name()} with server (#{err})"
            else
                options.success data

        @connection.on 'players_' + method, (data) =>
            switch method
                when 'create' then
                when 'read'
                    for v in data
                        if @get(v.id)
                            ship = @get(v.id)
                            ship.mesh.position.copy(v.pos)
                            ship.mesh.rotation.copy(v.dir)
                        else if v.id isnt @selfId
                            pos = new THREE.Vector3(v.pos)
                            ship = new Ship({id:v.id,position:pos})
                            @add(ship)
                            @parentScene.add(ship.mesh)
                when 'update'
                    for v in data
                        if @get(v.id)
                            ship = @get(v.id)
                            ship.mesh.position.copy(v.pos)
                            ship.mesh.rotation.copy(v.dir)
                        else if v.id isnt @selfId
                            pos = new THREE.Vector3(v.pos)
                            ship = new Ship({id:v.id,position:pos})
                            @add(ship)
                            @parentScene.add(ship.mesh)
                when 'delete'
                    if @get(data)
                        @parentScene.remove(@get(data).mesh)
                        @remove(@get(data))