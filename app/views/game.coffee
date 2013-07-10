Game = require 'models/game'

module.exports = class GameView extends Backbone.View
    className: 'game'

    el: 'body.application'

    template: require 'views/templates/game'

    initialize: ->
        window.game = SpaceBees.Models.Game = new Game()
        #@game.animate()
        return


    render: ->
        this.el.html template