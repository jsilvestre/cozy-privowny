async = require "async"

Identity = require './server/models/identity'
PrivownyConfig = require './server/models/privownyconfig'
MesInfosStatuses = require './server/models/mesinfosstatuses'
User = require './server/models/user'
CozyInstance = require './server/models/cozyinstance'
BrowsedCompany = require './server/models/browsedcompany'
WebInput = require './server/models/webinput'

# Create all requests
module.exports = init = (callback) ->
    all = (doc) -> emit doc._id, doc

    allCompanyByPOID = (doc) -> emit doc.poCompanyId, doc
    allParametersByPOID = (doc) -> emit doc.poParamId, doc

    prepareRequests = []

    # Create request and the document if not existing
    prepareRequests.push (callback) ->
        PrivownyConfig.defineRequest 'all', all, (err) ->
            if err
                callback err
            else
                PrivownyConfig.getConfig (err, pc) ->
                    if err?
                        msg = "Internal error occurred, can't load the config"
                        console.log msg
                        callback err
                    else
                        if pc.length is 0
                            console.log "No existing document, creating..."
                            token = require('./server/helpers/password')(12)
                            PrivownyConfig.create password: token, (err, pc) ->
                                console.log "Config created."
                            callback err
                        else
                            callback err

    # Create request and the document if not existing
    prepareRequests.push (callback) ->
        Identity.defineRequest 'all', all, (err) ->
            if err
                callback err
            else
                Identity.getIdentity (err, ide) ->
                    if err?
                        msg = "Internal error occurred, can't load the identity"
                        console.log msg
                        callback err
                    else
                        if ide.length is 0
                            console.log err if err?
                            console.log "No existing document, creating..."
                            fake =
                                firstName: "Joseph"
                                lastName: "Silvestre"
                                birthDate: "1990-02-02"
                            Identity.create fake, (err, ide) ->
                                console.log "Identity initialized."
                                callback err
                        else
                            callback err

    prepareRequests.push (callback) ->
        User.defineRequest 'all', all, callback

    prepareRequests.push (callback) ->
        MesInfosStatuses.defineRequest 'all', all, callback

    prepareRequests.push (callback) ->
        CozyInstance.defineRequest 'all', all, callback

    prepareRequests.push (callback) ->
        BrowsedCompany.defineRequest 'allCompanyByPOID', allCompanyByPOID, (err) ->
            callback err

    prepareRequests.push (callback) ->
        WebInput.defineRequest 'allParametersByPOID', allParametersByPOID, (err) ->
            callback err

    async.series prepareRequests, (err, results) ->
        callback(err)

# so we can do "coffee init"
if not module.parent
    init (err) ->
        if err
            console.log "init failled"
            console.log err.stack
        else
            console.log "init success"