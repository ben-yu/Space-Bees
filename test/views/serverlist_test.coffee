ServerlistView = require 'views/serverlist'

describe 'ServerlistView', ->
    beforeEach ->
        @view = new ServerlistView()

    it 'should exist', ->
        expect(@view).to.be.ok
