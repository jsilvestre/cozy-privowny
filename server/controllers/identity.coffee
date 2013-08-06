Identity = require '../models/identity'
PrivownyConfig = require '../models/privownyconfig'
MesInfosStatuses = require '../models/mesinfosstatuses'
User = require '../models/user'
CozyInstance = require '../models/cozyinstance'

module.exports = (app) ->

    get: (req, res) ->

       MesInfosStatuses.getStatuses (err, mis) ->

            errorMsg = "Une erreur fatale s'est produite. Merci de " + \
                       "contacter un administrateur Cozy pour qu'il " + \
                       "débloque votre situation."

            if err? or not mis?
                res.error 500, errorMsg

            # We don't send the token all the time to prevent a potential
            # security issue (parsing the html code to get the token, request
            # the app to get the identity)
            unless mis.privowny_registered
                Identity.getIdentity (err, ide) ->

                    errorMsg = "Error while retrieving the information."
                    if err?
                        res.error 500, errorMsg, err
                    else
                        User.getUser (err, user) ->
                            if err
                                res.error 500, errorMsg, err
                            else
                                merged = {}
                                merged.firstName = ide.firstName
                                merged.lastName = ide.lastName
                                merged.email = user.email
                                merged.birthdate = ide.birthdate
                                console.log merged, ide
                                res.send 200, merged

                                # A request means the user is registered on privowny
                                MesInfosStatuses.getStatuses (err, mis) ->
                                    mis.privowny_registered = true
                                    mis.save mis, (err) ->
                                        msg = "An error occurred while " + \
                                              "updating the status."
                                        if err?
                                            console.log msg, err
            else
                res.error 403, "La ressource n'est plus disponible. " + \
                               "Merci de contacter un administrateur Cozy " + \
                               "pour qu'il débloque votre situation."

    main: (req, res) ->
        MesInfosStatuses.getStatuses (err, mis) ->

            errorMsg = "Une erreur fatale s'est produite. Merci de " + \
                       "contacter un administrateur Cozy pour qu'il " + \
                       "débloque votre situation."

            if err? or not mis?
                res.error 500, errorMsg

            doRender = (append, askOauthRegistration) ->
                opts =
                    token: append
                    askOauthRegistration: askOauthRegistration
                res.render 'index.jade', opts, (err, html) ->
                    res.send 200, html

            # We don't send the token all the time to prevent a potential
            # security issue (parsing the html code to get the token, request
            # the app to get the identity)
            askOauthRegistration = mis.privowny_registered \
                                   and not mis.privowny_oauth_registered
            unless mis.privowny_registered
                PrivownyConfig.getConfig (err, pc) ->

                    res.error 500, errorMsg if err? or not pc?

                    CozyInstance.getInstance (err, ci) ->
                        append = "?cozy_token=#{pc.password}&host=#{ci.domain}"
                        doRender append, askOauthRegistration
            else
                if req.params.lenght > 0
                    target = decodeURIComponent req.params
                else
                    target = ""
                doRender target, askOauthRegistration


