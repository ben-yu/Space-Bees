console.log "app node file", process.cwd()
express = require 'express'

GameServer = require './gameserver'
mongoose = require 'mongoose'

exports.startServer = (port, path, callback) -> 
    p = process.env.PORT || port
    
    app = express()
    path = require 'path'
    app.use express.static(path.resolve(__dirname, '../public'))
    app.use express.bodyParser()

    # root
    app.get '/', (req, res) -> 
        res.sendfile(path.resolve(__dirname, '../public/index.html'))
    ###    
    # Mongo
    mongoose.connect('mongodb://localhost/spacebees')

    Account = new mongoose.Schema
        type: String
        uid : String
        username : String
        password : String

    User = new mongoose.Schema
        firstName : String,
        lastName : String,
        email : String,

        accounts : [Account]

    app.post '/auth' , (req, res) ->
        console.log JSON.stringify(req.body)
        user = req.body
        db.collection 'users', (err, collection) ->
            collection.insert user, {safe:true}, (err,response) ->
                if err
                    res.send 'Error: '
                else
                    res.send 'Success'
    ###
    server = app.listen p

    # Sockets
    io = require('socket.io').listen server
    io.set('log level', 1)

    # Start Game Server
    gs = new GameServer(io)
    #gs.run()
    
    console.log 'Listening on port: ' + p

isHeroku = process.env.IS_HEROKU
if isHeroku
    exports.startServer()