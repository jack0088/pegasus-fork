local pretty = require "pretty"
local pegasus = require "pegasus"
local router = require("pegasus.plugin.router")()

local server = pegasus{
    plugins = {router},
    port = 8888
}

--router:any("*anything", function(params, method) -- TODO fix so that request and response are available here?
router:any("/index", function(request, response, params)
    response:statusCode(200)
    response:addHeader("Content-Type", "text/plain")
    response:write("all right you are here " .. request:method() .. " " .. (params.anything or ""))
end)

router:get("/:point/*sub", function(request, response, params)
    response:statusCode(200)
    response:addHeader("Content-Type", "text/plain")
    response:write(string.format("reached a REST endpoint %s with subdomain %s", params.point, params.sub))
end)

server:run(function(request, response)
    response:writeDefaultErrorMessage(404)
end)
