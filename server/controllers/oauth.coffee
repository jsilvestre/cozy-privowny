MesInfosStatuses = require '../models/mesinfosstatuses'
PrivownyConfig = require '../models/privownyconfig'
request = require 'request'

db = {}
clientID = "clientId"
clientSecret = "clientSecret"
host = process.env.HOST

module.exports = (app) ->

    initiate: (req, res) ->
        url = "http://mesinfos.privowny.com/PrivownyAPI/oauth/authorize.dispatch?response_type=code&client_id=clientId&client_secret=clientSecret&redirect_uri=#{host}/oauth/authorize"
        res.redirect url

    authorize: (req, res) ->

        db.code = code = req.query.code
        url = "http://mesinfos.privowny.com/PrivownyAPI/oauth/token.dispatch?response_type=code&client_id=clientId&client_secret=clientSecret&redirect_uri=#{host}/oauth/authorize&code=#{db.code}&grant_type=authorization_code"

        # Authorization
        request.get {url: url, json: true}, (err, response, body) ->

            if err? or not (res?.statusCode is 200) or not body? or not body.access_token?
                statusCode = 500
                console.log "Error occurred from Privowny server -- #{err}"
            else
                statusCode = 200

                PrivownyConfig.getConfig (err, pc) ->
                    console.log "Can't get PrivownyConfig -- #{err}" if err?
                    pc.updateAttributes token: body, (err) ->
                        if err?
                            msg = "Fail to update PrivownyConfig -- #{err}"
                            console.log msg
                        else
                            # update privonwy oauth status
                            MesInfosStatuses.getStatuses (err, mis) ->
                                mis.privowny_oauth_registered = true
                                mis.save mis, (err) ->
                                    if err?
                                        console.log "Oauth::authorize > #{err}"

                                    # dev mode
                                    if host is "http://localhost:9262"
                                        res.redirect "/"
                                    else
                                        res.redirect "/#apps/privowny/"