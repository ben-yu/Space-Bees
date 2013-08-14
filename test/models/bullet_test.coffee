BulletModel = require 'models/bullet'

describe 'BulletModel', ->
    beforeEach ->
        @model = new BulletModel()

    it 'should exist', ->
        expect(@model).to.be.ok
