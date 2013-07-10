MissileModel = require 'models/missile'

describe 'MissileModel', ->
    beforeEach ->
        @model = new MissileModel()

    it 'should exist', ->
        expect(@model).to.be.ok
