module.exports = (app) ->

    shortcuts = require './helpers/shortcut'
    express   = require 'express'

    # all environments
    app.configure ->
        app.set 'views', __dirname + '/../client'
        app.engine '.html', require('jade').__express

        app.use express.bodyParser
            keepExtensions: true

        # extend express to DRY controllers
        app.use shortcuts

    #test environement
    app.configure 'test', ->

    #development environement
    app.configure 'development', ->
        app.use express.logger 'dev'
        app.use express.errorHandler
            dumpExceptions: true
            showStack: true

    #production environement
    app.configure 'production', ->
        app.use express.logger()
        app.use express.errorHandler
            dumpExceptions: true
            showStack: true

    # static middleware
    app.use express.static __dirname + '/../client/public',
        maxAge: 86400000
