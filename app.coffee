console.log "app node file", process.cwd()

express = require 'express'
app = express()

app.use(express.static __dirname+'/public')

GameServer = require './server/gameserver'

exports.startServer = (port, path, callback) -> 
    p = process.env.PORT || port
    app.get '/', (req, res) -> 
        res.sendfile './public/index.html'

    server = app.listen p
    io = require('socket.io').listen server

    gs = new GameServer(io)
    gs.run()

    io.sockets.on 'connection', (socket) =>
        socket.on 'create', (data) =>
            console.log data


    console.log 'Listening on port: ' + p

isHeroku = process.env.IS_HEROKU
if isHeroku
    exports.startServer()