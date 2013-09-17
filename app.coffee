console.log "app node file", process.cwd()

express = require 'express'
app = express()

app.use(express.static __dirname+'/public')

GameServer = require './server/gameserver'

passport = require 'passport'
FacebookStrategy = require('passport-facebook').Strategy

strat = new FacebookStrategy {
    clientID:'154939177928888',
    clientSecret:'a9d9813dd3c4df68f8dbcdb38245111d',
    callbackURL: "http://localhost:3333/auth/facebook/callback"},(accessToken, refreshToken, profile, done) ->
        # do stuff with profile
        console.log 'find user'
        done(null,null)

passport.use strat

exports.startServer = (port, path, callback) -> 
    p = process.env.PORT || port
    app.get '/', (req, res) -> 
        res.sendfile './public/index.html'

    app.get '/auth/facebook', passport.authenticate('facebook')

    app.get '/auth/facebook/callback', passport.authenticate('facebook', { successRedirect: '/', failureRedirect: '/login' })

    server = app.listen p

    io = require('socket.io').listen server

    io.set('log level', 1)

    gs = new GameServer(io)
    #gs.run()
    
    console.log 'Listening on port: ' + p

isHeroku = process.env.IS_HEROKU
if isHeroku
    exports.startServer()