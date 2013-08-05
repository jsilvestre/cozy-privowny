MesInfosStatuses = require '../models/mesinfosstatuses'

module.exports = (app) ->

    get: (req, res) ->
        MesInfosStatuses.getStatuses (err, mis) ->
            mis.privowny_oauth_registered = true
            mis.save mis, (err) ->
                if err?
                    console.log "Oauth::get > #{err}"
                else
                    res.redirect "back"