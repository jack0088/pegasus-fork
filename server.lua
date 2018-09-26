local pretty = require "lib.pretty"
local icarus = require "icarus"
local cache = require "icarus.plugin.cache"
local router = require "api"

local server = icarus{
    port = 8888,
    location = "~/.code/ru/",
    plugins = {
        cache,
        router
    }
}

server:run()

-- TODO figure out how redirecting will work
-- TODO make broadcaster work to broadcast updates/stream data to client without having the client to pull
-- TODO implement the flatDB database / or custom implementation for json file storage
-- TODO figure out how text messages and simmilar sensible data could be saved at client pc and not the database to save space and privacy
