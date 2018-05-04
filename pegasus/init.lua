local socket = require "socket"
local class = require("class").class
local Handler = require "pegasus.handler"

local Pegasus = class()

function Pegasus:new(settings)
    settings = settings or {}
    self.host = settings.host or "*"
    self.port = settings.port or 8888
    self.location = settings.location or ""
    self.plugins = settings.plugins or {}
    self.timeout = settings.timeout or 1
    return self
end

function Pegasus:start(callback)
    local handler = Handler(callback, self.location, self.plugins)
    local server = assert(socket.bind(self.host, self.port))
    local ip, port = server:getsockname()

    print(string.format("Pegasus is up on %s:%s", ip, port))

    while true do
        local client = server:accept()
        client:settimeout(self.timeout, "b")
        handler:processRequest(self.port, client)
    end
end

return Pegasus
