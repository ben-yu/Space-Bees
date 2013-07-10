MainView = require 'views/main'

describe 'MainView', ->
    beforeEach ->
        @view = new MainView()

    it 'should exist', ->
        expect(@view).to.be.ok
