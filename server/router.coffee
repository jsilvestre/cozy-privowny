module.exports = (app) ->
    token = require('./controllers/token')(app)
    identity = require('./controllers/identity')(app)
    oauth = require('./controllers/oauth')(app)

    # fetch on params
    app.param 'tokensecure', token.check

    # CRUD routes
    app.get   '/public/token/:tokensecure/identity/?', identity.get
    app.get   '/oauth/', oauth.get
    app.get   '/target/*', identity.target
    app.post   '/target/*', identity.target
    app.get   '/proxy/*', identity.main
    app.get   '/', identity.main