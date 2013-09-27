db = require '../db/cozy-adapter'

# User defines user that can interact with the Cozy instance.
module.exports = User = db.define 'user',
    id: String
    email: String
    password: String
    timezone:
        type: String
        default: 'Europe/Paris'
    owner:
        type: Boolean
        default: false
    activated:
        type: Boolean
        default: false

User.getUser = (callback) ->
    User.request 'all', (err, user) ->
        user = user[0] if user? and user.length > 0
        callback(err, user)