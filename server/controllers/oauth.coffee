MesInfosStatuses = require '../models/mesinfosstatuses'
request = require 'request'

db = {}
clientID = "clientId"
clientSecret = "clientSecret"
host = "http://localhost:9262"

module.exports = (app) ->

    initiate: (req, res) ->
        url = "http://privowny.com.ua/PrivownyAPI/oauth/authorize.dispatch?response_type=code&client_id=clientId&client_secret=clientSecret&redirect_uri=#{host}/oauth/authorize"
        res.redirect url

    authorize: (req, res) ->

        db.code = code = req.query.code
        url = "http://privowny.com.ua/PrivownyAPI/oauth/token.dispatch?response_type=code&client_id=clientId&client_secret=clientSecret&redirect_uri=#{host}/oauth/authorize&code=#{db.code}&grant_type=authorization_code"

        # Authorization
        request.get {url: url, json: true}, (err, response, body) ->

            if err? or not (res?.statusCode is 200)
                statusCode = 500
                console.log "Error occurred from Privowny server -- #{err}"
            else
                statusCode = 200
                db.token = body

                # update privonwy oauth status
                MesInfosStatuses.getStatuses (err, mis) ->
                    mis.privowny_oauth_registered = true
                    mis.save mis, (err) ->
                        if err?
                            console.log "Oauth::authorize > #{err}"
                        else
                            url = "http://privowny.com.ua/PrivownyAPI/api/companies?access_token=#{db.token.access_token}"
                            request.get {url: url, json: true}, (err, response, body) ->
                                console.log err if err?
                                console.log res?.statusCode
                                console.log body

                            # dev mode
                            if host is "http://localhost:9262"
                                res.redirect "/"
                            else
                                res.redirect "/#apps/privowny/"