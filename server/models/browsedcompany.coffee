db = require '../db/cozy-adapter'

module.exports = BrowsedCompany = db.define 'BrowsedCompany',
    id: String
    origin:
        type: String
        default: "privowny"
    companyName:
        type: String
        default: ""
    poCompanyId: Number

BrowsedCompany.findByPOID = (company, callback) ->
    BrowsedCompany.request 'allCompanyByPOID', key: company.id, (err, bc) ->
        bc = bc[0] if bc? and bc.length > 0
        callback err, bc

