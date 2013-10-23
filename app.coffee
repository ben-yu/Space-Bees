console.log "app node file", process.cwd()

express = require 'express'
app = express()

app.use(express.static __dirname+'/public')

GameServer = require './server/gameserver'

mongoose = require 'mongoose'

exports.startServer = (port, path, callback) -> 
    p = process.env.PORT || port

    # root
    app.get '/', (req, res) -> 
        res.sendfile './public/index.html'

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
        console.log req.params
        console.log req.query
        console.log JSON.stringify(req.body)
        res.send 'Success'

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