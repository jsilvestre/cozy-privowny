module.exports = (app) ->
    token = require('./controllers/token')(app)
    identity = require('./controllers/identity')(app)

    # fetch on params
    app.param 'tokensecure', token.check

    # CRUD routes
    app.get   '/public/token/:tokensecure/identity/?', identity.get
    app.get   '/', identity.main