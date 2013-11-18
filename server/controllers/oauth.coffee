MesInfosStatuses = require '../models/mesinfosstatuses'
PrivownyConfig = require '../models/privownyconfig'
CozyInstance = require '../models/cozyinstance'
request = require 'request'

db = {}
clientID = "clientId"
clientSecret = "clientSecret"
host = null

module.exports = (app) ->

    initiate: (req, res) ->
        CozyInstance.getInstance (err, ci) ->
            host = "https://#{ci.domain}/apps/privowny"
            url = "https://mesinfos.privowny.com/api/oauth/authorize.dispatch?response_type=code&client_id=clientId&client_secret=clientSecret&redirect_uri=#{host}/oauth/authorize"
            res.redirect url

    authorize: (req, res) ->

        db.code = code = req.query.code
        url = "https://mesinfos.privowny.com/api/oauth/token.dispatch?response_type=code&client_id=clientId&client_secret=clientSecret&redirect_uri=#{host}/oauth/authorize&code=#{db.code}&grant_type=authorization_code"

        # Authorization
        request.get {url: url, json: true}, (err, response, body) ->

            if err? or not (res?.statusCode is 200) or not body? or not body.access_token?
                console.log "Error occurred from Privowny server -- #{err}"
            else
                PrivownyConfig.getConfig (err, pc) ->
                    console.log "Can't get PrivownyConfig -- #{err}" if err?
                    pc.updateAttributes token: body, (err) ->
                        if err?
                            msg = "Fail to update PrivownyConfig -- #{err}"
                            console.log msg
                        else
                            # update privonwy oauth status
                            MesInfosStatuses.getStatuses (err, statuses) ->
                                if not err? and statuses?
                                    statuses.privowny_oauth_registered = true
                                    statuses.save statuses, (err) ->
                                        if err?
                                            msg = "Oauth::authorize > #{err}"
                                            console.log msg

                                        # dev mode
                                        if host is "http://localhost:9262"
                                            res.redirect "/"
                                        else
                                            res.redirect "https://mesinfos." + \
                                                  "privowny.com/"
                                else
                                    msg = "Can't retrieve MesInfosStatuses"
                                    console.log msg
