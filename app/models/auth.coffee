module.exports = class AuthModel extends Backbone.Model
    defaults :
        username : ""
        password : ""
        firstName : ""
        lastName : ""
        uid : ""
        email : ""
        loginStatus : false

    url : "http://localhost:3333/auth"
