db = require '../db/cozy-adapter'

module.exports = PrivownyConfig = db.define 'privownyconfig',
    id: String
    password:
        type: String
        default: ""
    token:
        type: Object
        default: null
    lastUpdate:
        type: Date
        default: null

PrivownyConfig.getConfig = (callback) ->
    PrivownyConfig.request 'all', (err, pc) ->
        pc = pc[0] if pc? and pc.length > 0
        callback(err, pc)