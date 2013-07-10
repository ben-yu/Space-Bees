ShipModel = require 'models/ship'

describe 'ShipModel', ->
    beforeEach ->
        @model = new ShipModel()

    it 'should exist', ->
        expect(@model).to.be.ok
