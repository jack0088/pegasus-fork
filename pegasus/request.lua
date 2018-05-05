local class = require("lib.class").class
local Request = class()

Request.PATTERN_PATH = "(%S+)%s*"
Request.PATTERN_METHOD = "^(.-)%s"
Request.PATTERN_PROTOCOL = "(HTTP%/%d%.%d)"
Request.PATTERN_HEADER = "([%w-]+): ([%w %p]+=?)"
Request.PATTERN_QUERY_STRING = "([^=]*)=([^&]*)&?"
Request.PATTERN_REQUEST = (Request.PATTERN_METHOD .. Request.PATTERN_PATH ..Request.PATTERN_PROTOCOL)

function Request:new(port, client)
    self.client = client
    self.port = port
    self.ip = client:getpeername()
    self.firstLine = nil
    self._method = nil
    self._path = nil
    self._params = {}
    self._headers_parsed = false
    self._headers = {}
    self._form = {}
    self._is_valid = false
    self._body = ""
    self._content_done = 0
    return self
end

function Request:parseFirstLine()
    if self.firstLine then
        return
    end

    local status, partial
    self.firstLine, status, partial = self.client:receive()

    if not self.firstLine or status == "timeout" or partial == "" or status == "closed" then
        return
    end

    -- Parse firstline http: METHOD PATH PROTOCOL,
    -- GET Makefile HTTP/1.1
    local method, path, protocol = string.match(self.firstLine, Request.PATTERN_REQUEST) -- luacheck: ignore protocol

    if not method then
        --self.client:close() -- close client socket immediately!
        return
    end

    local filename, querystring
    if #path > 0 then
        filename, querystring = string.match(path, "^([^#?]+)[#|?]?(.*)")
    else
        filename = ""
    end

    if not filename then
        return
    end

    self._path = filename or path
    self._method = method
    self._query_string = querystring
end

function Request:parseURLEncoded(value, _table) -- luacheck: ignore self
    if value and next(_table) == nil then -- value exists and _table is empty
        for k, v in string.gmatch(value, Request.PATTERN_QUERY_STRING) do
            _table[k] = v
        end
    end
    return _table
end

function Request:params()
    self:parseFirstLine()
    return self:parseURLEncoded(self._query_string, self._params)
end

function Request:post()
    if self:method() ~= "POST" then return end
    local data = self:receiveBody()
    return self:parseURLEncoded(data, {})
end

function Request:path()
    self:parseFirstLine()
    return self._path
end

function Request:method()
    self:parseFirstLine()
    return self._method
end

function Request:headers()
    if self._headers_parsed then
        return self._headers
    end

    self:parseFirstLine()

    local data repeat
        data = self.client:receive()
        local key, value = string.match(data, Request.PATTERN_HEADER)
        if key and value then
            self._headers[key] = value
        end
    until not data or data:len() == 0

    self._headers_parsed = true
    self._content_length = tonumber(self._headers["Content-Length"] or 0)
    return self._headers
end

function Request:receiveBody(size)
    if not self._content_length or self._content_done >= self._content_length then -- do we have content?
        return false
    end

    size = size or self._content_length
    local fetch = math.min(self._content_length-self._content_done, size) -- fetch in chunks
    local data, err, partial = self.client:receive(fetch)

    if err == "timeout" then
        data = partial
    end

    self._content_done = self._content_done + #data
    return data
end

return Request
