db = require '../db/cozy-adapter'

module.exports = CozyInstance = db.define 'CozyInstance',
    domain: String
    locale: String
    helpUrl: String

CozyInstance.getInstance = (callback) ->
    CozyInstance.request 'all', (err, ide) ->
        ide = ide[0] if ide? and ide.length > 0
        callback(err, ide)