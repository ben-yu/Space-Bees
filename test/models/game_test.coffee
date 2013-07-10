GameModel = require 'models/game'

describe 'GameModel', ->
    beforeEach ->
        @model = new GameModel()

    it 'should exist', ->
        expect(@model).to.be.ok
