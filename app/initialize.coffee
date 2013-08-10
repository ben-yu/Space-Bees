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

    LauncherView = require 'views/launcher'

    SpaceBees.Views.Launcher = new LauncherView()