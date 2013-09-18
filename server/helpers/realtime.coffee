PrivownyConfig = require '../models/privownyconfig'
initializer = require('cozy-realtime-adapter')

module.exports = (app, server) ->

    watchedEvents = ['privownyconfig.update']
    realtime = initializer server: server, watchedEvents

    triggerPolling = ->
        PrivownyConfig.getConfig (err, pc) ->

            if pc? and pc.token isnt null and not err?

                proc = require '../lib/processor'

                # if the server just started
                if proc.lastUpdate is null
                    proc.initialize pc
                    proc.startPolling()

            else
                msg = "Can't get PrivownyConfig or oAuth not enabled yet"
                console.log "#{msg} -- #{err}"

    triggerPolling()

    realtime.on 'privownyconfig.update', (event, id) ->
        triggerPolling()