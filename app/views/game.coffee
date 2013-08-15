module.exports = class GameView extends Backbone.View
    className: 'game'

    el: 'div#game'

    template: require 'views/templates/game'

    initialize: =>
        @render()
        return


    render: =>
        this.$el.html @template