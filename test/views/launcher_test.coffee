LauncherView = require 'views/launcher'

describe 'LauncherView', ->
    beforeEach ->
        @view = new LauncherView()

    it 'should exist', ->
        expect(@view).to.be.ok
