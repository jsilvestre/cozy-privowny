Identity = require '../models/identity'
PrivownyConfig = require '../models/privownyconfig'
MesInfosStatuses = require '../models/mesinfosstatuses'
User = require '../models/user'

module.exports = (app) ->

    get: (req, res) ->
        Identity.getIdentity (err, ide) ->
            res.send 500, "Error while retrieving the information.", err if err?
            User.getUser (err, user) ->
                if err
                    res.send 500, "Error while retrieving the information.", err
                else
                    merged = {}
                    merged.firstName = ide.firstName
                    merged.lastName = ide.lastName
                    merged.email = user.email
                    merged.birthdate = ide.birthdate
                    res.send 200, merged

    main: (req, res) ->
        MesInfosStatuses.getStatuses (err, mis) ->

            errorMsg = "Une erreur fatale s'est produite. Merci de contacter un administrateur Cozy pour qu'il débloque votre situation."

            if err? or not mis?
                res.error 500, errorMsg

            doRender = (token) ->
                res.render 'index.jade', {token: token}, (err, html) ->
                    res.send 200, html
            # We don't send the token all the time to prevent a potential
            # security issue (parsing the html code to get the token, request
            # the app to get the identity)
            unless mis.privowny_registered
                PrivownyConfig.getConfig (err, pc) ->

                    if err? or not pc?
                        res.error 500, errorMsg

                    token = "?cozy_token=#{pc.password}"
                    doRender(token)
            else
                doRender("")


