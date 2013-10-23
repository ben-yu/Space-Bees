AuthModel = require 'models/auth'

describe 'AuthModel', ->
    beforeEach ->
        @model = new AuthModel()

    it 'should exist', ->
        expect(@model).to.be.ok
