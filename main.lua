local pretty = require "pretty"
local pegasus = require "pegasus"
local router = require("pegasus.plugin.router")()

local server = pegasus{
    plugins = {router},
    port = 8888
}

router:get("/:lol", function(request, response, params)
    response:addHeader("Content-Type", "text/plain")
    response:statusCode(200)
    response:write(string.format("reached a REST endpoint with id %s", params.lol))
end)

server:start(function(request, response)
    response:addHeader("Content-Type", "text/plain")
    response:statusCode(200)
    response:write "Server is running..."
end)
