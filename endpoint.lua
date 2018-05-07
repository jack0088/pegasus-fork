local route = require("pegasus.plugin.router")()

route:get("/", function(request, response)
    response:statusCode(200)
    print(request:path())
end)

route:get("/subscribe/:topic", function(request, response, params)
    if response.status == 200 then
        response:forward("/")
    end
    response:statusCode(200)
    response:addHeader("Content-Type", "text/plain")
    response:write(string.format("run routine subscribe to topic `%s` here...", params.topic))
end)

return route