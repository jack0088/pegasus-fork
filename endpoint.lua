local router = require("pegasus.plugin.router")()

router:get("/subscribe/:topic", function(request, response, params)
    response:statusCode(200)
    response:addHeader("Content-Type", "text/plain")
    response:write(string.format("run routine subscribe to topic `%s` here...", params.topic))
end)

return router