Ship = require 'models/ship'

module.exports = class ActivePlayers extends Backbone.Collection
    model: Ship

    initialize: () ->
        @connection = window.socket

    sync: (method, model, options) ->
        console.log method
        options.data ?= {}
        @connection.emit 'players_' + method, model.toJSON(), options.data, (err, data) ->
            if err
                console.error "error in sync with #{method} #{@.name()} with server (#{err})"
            else
                options.success data

        @connection.on 'players_' + method, (data) ->
            console.log 'success!'
            #model.id = data.id