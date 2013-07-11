###initializer = require('cozy-realtime-adapter')
User = require '../models/user'
MesInfosIntegrator = require '../models/mesinfosintegrator'
MesInfosStatuses = require '../models/mesinfosstatuses'

module.exports = initRealtime = (app, server) ->

    watchedEvents = ['user.update', 'mesinfosstatuses.update']
    realtime = initializer server: server, watchedEvents

    # Detect the COZY status
    realtime.on 'user.update', (event, id) ->
        console.log "#{event} > #{id}"
        User.find id, (err, user) ->
            console.log "An error occurrend during user retrieval" if err?
            MesInfosStatuses.getStatuses (err, mis) ->
                if err?
                    console.log err
                else
                    attr = cozy_registered: user.activated
                    mis.updateAttributes attr, (err, mis) ->
                        console.log err if err?

    realtime.on 'mesinfosstatuses.update', (event, id) ->
        console.log "#{event} > #{id}"
        MesInfosIntegrator.getConfig (err, midi) ->
            if err?
                console.log err
            else
                retriever = require '../lib/retriever'
                retriever.init app.get('processor_url'), midi.password
                retriever.sendStatus midi.registration_status
###