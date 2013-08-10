Game = require 'models/game'
GameView = require 'views/game'
Loader = require 'lib/loader'

module.exports = class LauncherView extends Backbone.View
    className: 'launcher'

    template: require 'views/templates/launcher'

    el: 'div#launcher'

    events:
        "click .button-huge" : "startGame"

    initialize: =>
        @render()

    render: ->
        this.$el.html @template

    startGame: (event) ->
        this.$el.hide()
        
        SpaceBees.Views.Game = new GameView()

        window.game = SpaceBees.Models.Game = new Game()

        progress = document.getElementById 'progress'

        SpaceBees.Loader = new Loader({
            onLoad: () =>
                console.log "All Loaded"
                window.socket = new io.connect(window.location.hostname)
                progress.innerText = "Connecting to Server..."
                window.socket.on 'connect', () =>
                    SpaceBees.Models.Game.start()
                    progress.innerText = "Click to Play!"
            onError: (s) =>
                console.log "Error on " + s
            onProgress: (p,t,n) =>
                progress.innerText = Math.floor(p.loaded/p.total * 100) + "%"
                console.log "Loaded " + t + " : " + n + " ( " + p.loaded + " / " + p.total + " )."
        })

        SpaceBees.Loader.load({
            textures: {
                'missile' : 'textures/missiles/hellfire_skin.png'
                'scrapers1.diffuse' : 'textures/scrapers1/diffuse.jpg'
                'scrapers2.diffuse' : 'textures/scrapers2/diffuse.jpg'
                'chipmetal' : 'textures/terrain/chipmetal/texturemap.jpg'
            },
            texturesCube: {
                'interstellar' : "textures/skybox/interstellar/%1.jpg"
            },
            geometries: {
                'missile' : 'models/missiles/hellfire.js'
                'ship' : 'models/spaceship_0.js'
                'scrapers1' : 'models/scrapers1.js'
                'scrapers2' : 'models/scrapers2.js'
                'bee' : 'models/bee.js'
            },
            analysers : {},
            images: {
                'cursor' : 'images/cursor.png'
                'aim' : 'images/aim.png'
                'target_lock' : 'images/lock.png'
            }
        })
