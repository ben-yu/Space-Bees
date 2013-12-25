module.exports = class HealthbarView extends Backbone.View
    className: 'healthbar'

    el: 'div#healthbar'

    template: require 'views/templates/healthbar'

    initialize: =>
        @$el.html @template
        @bg =  $('#counter').get(0)
        @speedIndicator =  $('#speed')
        @ctx = @bg.getContext('2d')
        @imd = null
        @fullRad = Math.PI * 2
        @quartRad = Math.PI / 2

        @ctx.beginPath()
        @ctx.strokeStyle = '#FF0031'
        @ctx.lineCap = 'square'
        @ctx.closePath()
        @ctx.fill()
        @ctx.lineWidth = 20.0
        @ctx.shadowBlur = 30.0
        @ctx.shadowColor = "#FF0031"
        @imd = @ctx.getImageData(0, 0, 240, 240)

        @health = 1.0

        @render()
        return

    render: =>
        @ctx.putImageData(@imd, 0, 0)
        @ctx.beginPath()
        @ctx.arc(120, 120, 70, -(@quartRad), ((@fullRad) * @health) - @quartRad, false)
        @ctx.stroke()