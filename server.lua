local pretty = require "lib.pretty"
local pegasus = require "pegasus"
local router = require "endpoint" -- RESTful api

local server = pegasus{
    plugins = {router},
    port = 8888
}

server:run(function(request, response)
    -- response:writeFile("template/404.html")
    response:writeDefaultErrorMessage(404)
end)
