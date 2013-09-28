db = require '../db/cozy-adapter'

module.exports = MesInfosStatuses = db.define 'MesInfosStatuses',
    id: String
    cozy_registered:
        type: Boolean
        default: false
    privowny_registered:
        type: Boolean
        default: false
    privowny_oauth_registered:
        type: Boolean
        default: false
    google_oauth_registered:
        type: Boolean
        default: false

MesInfosStatuses.getStatuses = (callback) ->
    MesInfosStatuses.request 'all', (err, mis) ->
        mis = mis[0] if mis? and mis.length > 0
        callback(err, mis)