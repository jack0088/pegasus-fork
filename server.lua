local pretty = require "lib.pretty"
local pegasus = require "pegasus"
local cache = require "pegasus.plugin.cache"
local router = require "endpoint" -- RESTful api

local server = pegasus{
    port = 8888,
    location = "~/.code/ru/",
    plugins = {
        cache,
        router
    }
}

server:run(function(request, response)
    -- response:writeFile("template/404.html")
    response:writeDefaultErrorMessage(404)
end)

-- TODO figure out how redirecting will work
-- TODO make broadcaster work to broadcast updates/stream data to client without having the client to pull
-- TODO figure out how html templates could be refreshed with the streamed content (ajax? I want to avoid rendering them on the server)
-- TODO implement the flatDB database
-- TODO figure out how text messages and simmilar sensible data could be saved at client pc and not the database to save space and privacy
