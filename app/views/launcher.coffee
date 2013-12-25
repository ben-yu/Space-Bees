Game = require 'models/game'
GameView = require 'views/game'
Loader = require 'lib/loader'
FacebookView = require 'views/facebook'
AuthModel = require 'models/auth'

module.exports = class LauncherView extends Backbone.View
    className: 'launcher'

    template: require 'views/templates/launcher'

    el: 'div#launcher'

    events:
        "click .btn-success" : "startGame"
        "click .fb-signup" : "login"

    initialize: =>
        @facebook = new FacebookView
            appId: '154939177928888'
            scope: 'email'
        @facebook.loadSDK()
        @render()
        @facebook.getLoginStatus()

    render: ->
        this.$el.html @template
        $ () ->
            BV = new $.BigVideo()
            BV.init()
            BV.show('backgroundMovie.mp4',{ambient:true})

    login: (event) ->
        @facebook.triggerLogin "loginbutton"

    startGame: (event) ->
        this.$el.hide()
        $('#big-video-vid').remove()
        
        SpaceBees.Views.Game = new GameView()

        SpaceBees.Models.Game = new Game()

        progress = document.getElementById 'progress'

        SpaceBees.Loader = new Loader({
            onLoad: () =>
                console.log "All Loaded"
                window.socket = new io.connect(window.location.hostname)
                progress.innerText = "Connecting to Server..."
                window.socket.on 'client_id', (client_id) =>
                    SpaceBees.Models.Game.start(client_id)
                    progress.innerText = "Click to Play!"

                #SpaceBees.Models.Game.start(0)
                #progress.innerText = "Click to Play!"
            onError: (s) =>
                console.log "Error on " + s
            onProgress: (p,t,n) =>
                progress.innerText = Math.floor(p.loaded/p.total * 100) + "%"
                #console.log "Loaded " + t + " : " + n + " ( " + p.loaded + " / " + p.total + " )."
        })

        SpaceBees.Loader.load({
            textures: {
                'missile' : 'textures/missiles/hellfire_skin.png'
                'scrapers1.diffuse' : 'textures/scrapers1/diffuse.jpg'
                'scrapers2.diffuse' : 'textures/scrapers2/diffuse.jpg'
                'chipmetal' : 'textures/terrain/chipmetal/texturemap.jpg'
                'missile_particle' : 'textures/missiles/particle.png'
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
                'city': 'models/city/city.js'
            },
            analysers : {},
            images: {
                'cursor' : 'images/cursor.png'
                'aim' : 'images/aim.png'
                'target_lock' : 'images/lock.png'
            }
        })
