module.exports = class ServerlistView extends Backbone.View
    className: 'serverlist'

    el: 'body.serverlist'

    template: require 'views/templates/serverlist'

    render: ->
        this.el.html template