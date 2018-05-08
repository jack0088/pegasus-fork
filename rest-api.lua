local route = require("icarus.plugin.router")()

route:get("/subscribe/:topic", function(request, response, params)
    response:statusCode(200)
    response:addHeader("Content-Type", "text/plain")
    response:write(string.format("run routine subscribe to topic `%s` here...", params.topic))
    -- response:forward("/")
end)

return route