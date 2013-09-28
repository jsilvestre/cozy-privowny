db = require '../db/cozy-adapter'

module.exports = Identity = db.define 'Identity',
    id: String
    firstName:
        type: String
        default: ""
    lastName:
        type: String
        default: ""
    birthDate: Date

Identity.getIdentity = (callback) ->
    Identity.request 'all', (err, ide) ->
        ide = ide[0] if ide? and ide.length > 0
        callback(err, ide)