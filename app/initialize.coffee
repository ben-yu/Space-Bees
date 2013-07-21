@SpaceBees ?= {}
SpaceBees.Routers ?= {}
SpaceBees.Views ?= {}
SpaceBees.Models ?= {}
SpaceBees.Collections ?= {}

# Load App Helpers
require 'lib/helpers'
Loader = require 'lib/loader'
Game = require 'models/game'

# Initialize Router
require 'routers/main'

$ ->
    # Initialize Backbone History
    Backbone.history.start pushState: yes

    GameView = require 'views/game'

    SpaceBees.Views.Game = new GameView()

    window.game = SpaceBees.Models.Game = new Game()

    SpaceBees.Loader = new Loader({
        onLoad: () =>
            console.log "All Loaded"
            SpaceBees.Models.Game.start()
        onError: (s) =>
            console.log "Error on " + s
        onProgress: (p,t,n) =>
            console.log "Loaded" + t + ":" + n + " ( " + p.loaded + " / " + p.total + " )."
    })

    SpaceBees.Loader.load({
        textures: {
            'missile' : 'textures/missiles/hellfire_skin.png'
        },
        texturesCube: {
            interstellar : "textures/skybox/interstellar/%1.jpg"
        },
        geometries: {
            'missile' : 'models/missiles/hellfire.js'
            'ship' : 'models/spaceship_0.js'
        },
        analysers : {},
        images: {}
    })