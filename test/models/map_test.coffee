MapModel = require 'models/map'

describe 'MapModel', ->
    beforeEach ->
        @model = new MapModel()

    it 'should exist', ->
        expect(@model).to.be.ok
