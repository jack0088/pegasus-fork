local route = require("pegasus.plugin.router")()

route:get("/subscribe/:topic", function(request, response, params)
    -- request:forward("/index/foobar")
    response:statusCode(200)
    response:addHeader("Content-Type", "text/plain")
    response:write(string.format("run routine subscribe to topic `%s` here...", params.topic))
end)

return route