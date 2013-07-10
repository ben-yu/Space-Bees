express = require 'express'
app = express()

app.use(express.static __dirname+'/public') 

exports.startServer = (port, path, callback) -> 
	app.get '/', (req, res) -> 
		res.sendfile './public/index.html'

	server = app.listen port
	io = require('socket.io').listen server

	console.log 'Listening on port:' + port

