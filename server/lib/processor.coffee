request = require 'request'
moment = require 'moment'
async = require 'async'

MesInfosStatuses = require '../models/mesinfosstatuses'
BrowsedCompany = require '../models/browsedcompany'
WebInput = require '../models/webinput'

class Processor

    @urlPrefix: "https://mesinfos.privowny.com/api/api/"
    @urls:
        'companies': "companies?" # optional: id=companyID

        # companyID=companyID for company's parameter
        # id=parameterID for parameter details
        'parameters': "parameters?"

    token: null
    lastUpdate: null
    timeout = null

    initialize: (privownyConfig) ->
        @token = privownyConfig.token.access_token
        @lastUpdate = privownyConfig.lastUpdate
        @privownyConfig = privownyConfig

    startPolling: ->

        console.log "Start polling..."

        @poll =>
            clearTimeout @timeout
            @lastUpdate = moment().toDate()
            attr =
                lastUpdate: @lastUpdate

            @privownyConfig.updateAttributes attr, (err) =>
                if err?
                    console.log "Error while updating privowny data -- #{err}"
                else
                    console.log "Privowny data updated."

                # day after between 00:00am and 00:30am
                delta =  Math.floor(Math.random() * 30) + 1
                now = moment()
                nextUpdate = now.clone().add(1, 'days')
                                    .hours(0)
                                    .minutes(delta)
                console.log "\t> in #{nextUpdate.diff(now)/1000} seconds"

                format = "DD/MM/YYYY [at] HH:mm:ss"
                console.log "> Next update on #{nextUpdate.format(format)}"
                @timeout = setTimeout(
                    () =>
                        @startPolling()
                    , nextUpdate.diff(now))

    # We just poll the companies data
    poll: (callback) ->

        url = @getUrl 'companies'
        console.log "Get companies..."
        request.get url: url, json: true, (err, res, body) =>
            console.log err if err?

            if res? and res.statusCode? and res.statusCode is 401
                console.log "> Invalid token, starting the refreshing process."
                @refreshToken()

            else if res? and res.statusCode and res.statusCode is 200
                companies = body.companies || []
                process = (company, callback) =>
                    @_companyFactory company, callback

                async.each companies, process, (err) ->
                    callback err if callback?

    _companyFactory: (company, callback) ->
        BrowsedCompany.findByPOID company, (err, bc) =>

            companyName = company.companyName
            if not bc? or bc.length is 0
                msg = "Company #{companyName} does not exist, creating..."
                console.log msg
                company.poCompanyId = company.id
                BrowsedCompany.create company, (err, bc) =>
                    console.log err if err?
                    console.log "Company #{companyName} added."
                    @_getParametersByCompany company, callback
            else
                msg = "Company #{companyName} already exists, updating " + \
                      "parameters..."
                console.log msg
                @_getParametersByCompany company, callback

    _getParametersByCompany: (company, callback) ->
        companyName = company.companyName
        console.log "Get parameters..."
        url = @getUrl 'parameters', companyId: company.id
        request.get {url: url, json: true}, (err, res, body) =>
            console.log err if err?
            console.log res?.statusCode if err?

            if body? and body.success and body.parameters?
                console.log "Process parameters of company #{companyName}"
                process = (parameter, callback) =>
                    @_parameterFactory parameter.paramId, company, callback

                async.each body.parameters, process, (err) ->
                    console.log err if err?
                    console.log "Parameters retrieved for company " + \
                                "#{companyName}"
                    callback err


    _parameterFactory: (paramID, company, callback) ->
        url = @getUrl 'parameters', id: paramID
        request.get {url: url, json: true}, (err, res, body) =>
            hasResult = body? and body.success
            if err? or (not res? or res.statusCode isnt 200) or not hasResult
                console.log "Error retrieving parameters... -- #{err}"
                console.log res?.statusCode
                console.log body
            else
                WebInput.findByPOID paramID, (err, wi) =>
                    console.log err if err?

                    if not wi? or wi.length is 0
                        console.log "New parameter detected, adding to " + \
                                    "database..."
                        snippet = "#{company.companyName} - #{body.paramLabel}"
                        prm =
                            label: body.paramLabel
                            value: body.paramValue
                            siteName: ""
                            companyName: company.companyName
                            companyRename: company.companyName
                            poParamId: parseInt paramID
                            poPageId: body.pageId
                            poSiteId: body.siteId
                            snippet: snippet

                        WebInput.create prm, (err, wi) ->
                            console.log err if err?
                            console.log "Created parameter #{wi.label}"
                            callback()
                    else
                        console.log "Parameter already existing."
                        callback()

    # Hepler to build URL
    getUrl: (label, parameters = {}) ->
        parameters.access_token = @token
        append = ""
        for parameter, value of parameters
            if append is ""
                append += "#{parameter}=#{value}"
            else
                append += "&#{parameter}=#{value}"

        return "#{Processor.urlPrefix}#{Processor.urls[label]}#{append}"

    # When access_token is invalid, we can get a new refreshed one
    refreshToken: ->
        refreshToken = @privownyConfig.token.refresh_token
        url = "https://mesinfos.privowny.com/api/oauth/token.dispatch?" + \
              "client_id=clientId&client_secret=clientSecret&" + \
              "refresh_token=#{refreshToken}&grant_type=refresh_token"
        console.log "Refresh token..."
        request.get {url: url, json: true}, (err, res, body) =>
            if err? or (res? and res.statusCode is 401)
                msg = "> Invalid refresh token, must reask user consent"
                statusCode = if res?.statusCode then res.statusCode else ""
                console.log "#{msg} -- #{statusCode} -- #{err}"
                @token = null
                @privownyConfig.updateAttributes token: null, (err) =>
                    msg = "Couldn't update privownyConfig attributes -- #{err}"
                    console.log msg if err?

                    MesInfosStatuses.getStatuses (err, mis) ->
                        console.log err if err?
                        param = privowny_oauth_registered: false
                        mis.updateAttributes param, (err) ->
                            console.log err if err?
            else
                console.log "> Got a new access_token/refresh_token..."
                @privownyConfig.updateAttributes token: body, (err) =>
                    msg = "Couldn't update privownyConfig attributes -- #{err}"
                    if err?
                        console.log msg
                    else
                        timer = 300000 # 5 minutes
                        timerMin = (300000/1000/60)
                        msg = "> Token refreshed, start the polling " + \
                             "in #{timerMin} minutes..."
                        console.log msg
                        @token = body.access_token
                        @privownyConfig.token = body
                        setTimeout () =>
                                        @startPolling()
                                   , timer

module.exports = new Processor()