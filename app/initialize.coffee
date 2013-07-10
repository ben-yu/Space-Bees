@SpaceBees ?= {}
SpaceBees.Routers ?= {}
SpaceBees.Views ?= {}
SpaceBees.Models ?= {}
SpaceBees.Collections ?= {}

# Load App Helpers
require 'lib/helpers'

# Initialize Router
require 'routers/main'

$ ->
    # Initialize Backbone History
    Backbone.history.start pushState: yes

    @socket = new io.connect('http://localhost')

    GameView = require 'views/game'

    SpaceBees.Views.Game = new GameView()
