request = require 'request'
moment = require 'moment'

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

        @poll () =>
            @lastUpdate = moment().toDate()
            attr =
                lastUpdate: @lastUpdate

            @privownyConfig.updateAttributes attr, (err) =>
                if err?
                    console.log err
                else
                    console.log "Privowny data updated."

                    # day after between 00:00am and 00:30am
                    delta =  Math.floor(Math.random() * 30) + 1
                    now = moment()
                    nextUpdate = now.clone().add(1, 'days')
                                        .hours(0)
                                        .minutes(delta)
                                        .seconds(0)
                                        .diff(now)

                    @timeout = setTimeout(
                        () =>
                            @startPolling()
                        , nextUpdate)

    poll: (callback) ->

        url = @getUrl 'companies'
        request.get {url: url, json: true}, (err, res, body) =>
            console.log err if err?

            if res? and res.statusCode? and res.statusCode is 401
                console.log "> Invalid token, starting the refreshing process."
                @refreshToken()

            else if res? and res.statusCode and statusCode is 200
                companies = body.companies || []
                for company in companies
                    @_companyFactory company

                callback() if callback?

    refreshToken: ->
        console.log "Token refreshed, start the polling..."
        refreshToken = @token.refresh_token
        url = "https://mesinfos.privowny.com/api/oauth/token.dispatch?client_id=clientId&client_secret=clientSecret&refresh_token=#{refreshToken}&grant_type=refresh_token"
        request.get {url: url, json: true}, (err, res, body) =>
            if err?
                console.log "Cannot refresh token"
                console.log "Must reask user consent"
            else if res? and res.statusCode is 401
                console.log "> Invalid refresh token, must reask user consent"
            else
                @privownyConfig.updateAttributes token: body (err) =>
                    if err?
                        console.log "Must reask user consent"
                    else
                        @token = body


    _companyFactory: (company) ->

        BrowsedCompany.findByPOID company, (err, bc) =>

            if not bc? or bc.length is 0
                console.log "Company #{company.companyName} does not exist, creating..."
                cmp =
                    companyName: company.companyName
                    poCompanyId: company.id
                BrowsedCompany.create cmp, (err, bc) ->
                    console.log err if err?
                    console.log "Company #{company.companyName} added."
            else
                console.log "Company #{company.companyName} already exists, updating parameters..."
                url = @getUrl 'parameters', companyId: bc.poCompanyId
                request.get {url: url, json: true}, (err, res, body) =>
                    console.log err if err?

                    if body? and body.success and body.parameters?
                        console.log "Parameters for company #{company.companyName}"
                        for param in body.parameters
                            @_parameterFactory param.paramId, company

    _parameterFactory: (paramID, company) ->
        url = @getUrl 'parameters', id: paramID
        request.get {url: url, json: true}, (err, res, body) =>
            console.log err if err?
            param = body.parameters[0]
            WebInput.findByPOID paramID, (err, wi) =>
                console.log err if err?

                if not wi? or wi.length is 0
                    console.log "New parameter detected, adding to database..."
                    prm =
                        label: param.paramLabel
                        value: param.paramValue
                        siteName: ""
                        companyName: company.companyName
                        companyRename: company.companyName
                        poParamId: param.id
                        poPageId: null
                        poSiteId: null
                        snippet: "#{company.companyName} - #{param.paramLabel}"

                    WebInput.create prm, (err, wi) ->
                        console.log err if err?
                        console.log "Created parameter #{wi.label}"
                else
                    console.log "Parameter already existing."

    getUrl: (label, parameters = {}) ->
        parameters.access_token = @token
        append = ""
        for parameter, value of parameters
            if append is ""
                append += "#{parameter}=#{value}"
            else
                append += "&#{parameter}=#{value}"

        return "#{Processor.urlPrefix}#{Processor.urls[label]}#{append}"

module.exports = new Processor()