db = require '../db/cozy-adapter'

module.exports = WebInput = db.define 'webinput',
    id: String
    origin:
        type: String
        default: "privowny"
    label: String
    value: String
    encrypted:
        type: Boolean
        default: false
    siteName: String
    companyName: String
    companyRename: String
    poParamId: Number
    poPageId: Number
    poSiteId: Number
    snippet: String

WebInput.findByPOID = (paramID, callback) ->
    paramID = parseInt paramID
    WebInput.request 'allParametersByPOID', key: paramID, (err, wi) ->
        wi = wi[0] if wi? and wi.length > 0
        callback err, wi

