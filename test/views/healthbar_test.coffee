HealthbarView = require 'views/healthbar'

describe 'HealthbarView', ->
    beforeEach ->
        @view = new HealthbarView()

    it 'should exist', ->
        expect(@view).to.be.ok
