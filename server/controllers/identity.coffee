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

            res.error 500, errorMsg if err? or not mis?

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
                                res.send 200, merged
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
                askOauthRegistration = false unless askOauthRegistration?
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
            unless req.params?.length > 0
                PrivownyConfig.getConfig (err, pc) ->

                    res.error 500, errorMsg if err? or not pc?

                    CozyInstance.getInstance (err, ci) ->
                        append = "?cozy_token=#{pc.password}&host=#{ci.domain}"
                        doRender append, askOauthRegistration
            else
                target = decodeURIComponent req.params
                doRender target, askOauthRegistration

    # another proxy route
    target: (req, res) ->
        newUrl = decodeURIComponent req.params
        prefix = "https://mesinfos.privowny.com/"

        request = require 'request'
        opts =
            url: "#{prefix}#{newUrl}"
            method: "POST"
            form: req.body

        request opts, (err, response, body) ->
            console.log err if err?
            for headerLabel, headerValue of response.headers
                res.set headerLabel, headerValue
            res.send body

    # privowny calls it once when the user has successfully registered
    # so we update the cozy status
    markAsRegistered: (req, res) ->

       MesInfosStatuses.getStatuses (err, mis) ->

            errorMsg = "Une erreur fatale s'est produite. Merci de " + \
                       "contacter un administrateur Cozy pour qu'il " + \
                       "débloque votre situation."

            res.error 500, errorMsg if err? or not mis?

            MesInfosStatuses.getStatuses (err, mis) ->
                attr = privowny_registered: true
                mis.updateAttributes attr, (err) ->
                    if err?
                        msg = "An error occurred while " + \
                              "updating the status."
                        console.log msg, err
                    else
                        msg = "Status updated."
                        console.log msg

                    res.send 200, msg


