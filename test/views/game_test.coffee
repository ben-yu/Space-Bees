GameView = require 'views/game'

describe 'GameView', ->
    beforeEach ->
        @view = new GameView()

    it 'should exist', ->
        expect(@view).to.be.ok
