PrivownyConfig = require '../models/privownyconfig'

# Manage the Privowny token
module.exports = (app) ->

    check: (req, res, next, id) ->
        PrivownyConfig.getConfig (err, pc) ->
            return res.error 500, 'Internal server error', err if err

            if id is pc.password
                next()
            else
                res.send 401, "Unauthorized request."