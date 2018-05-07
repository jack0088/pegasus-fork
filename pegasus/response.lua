local STATUS_TEXT = {
    [100] = "Continue",
    [101] = "Switching Protocols",
    [200] = "OK",
    [201] = "Created",
    [202] = "Accepted",
    [203] = "Non-Authoritative Information",
    [204] = "No Content",
    [205] = "Reset Content",
    [206] = "Partial Content",
    [300] = "Multiple Choices",
    [301] = "Moved Permanently",
    [302] = "Found",
    [303] = "See Other",
    [304] = "Not Modified",
    [305] = "Use Proxy",
    [307] = "Temporary Redirect",
    [400] = "Bad Request",
    [401] = "Unauthorized",
    [402] = "Payment Required",
    [403] = "Forbidden",
    [404] = "Not Found",
    [405] = "Method Not Allowed",
    [406] = "Not Acceptable",
    [407] = "Proxy Authentication Required",
    [408] = "Request Time-out",
    [409] = "Conflict",
    [410] = "Gone",
    [411] = "Length Required",
    [412] = "Precondition Failed",
    [413] = "Request Entity Too Large",
    [414] = "Request-URI Too Large",
    [415] = "Unsupported Media Type",
    [416] = "Requested range not satisfiable",
    [417] = "Expectation Failed",
    [500] = "Internal Server Error",
    [501] = "Not Implemented",
    [502] = "Bad Gateway",
    [503] = "Service Unavailable",
    [504] = "Gateway Time-out",
    [505] = "HTTP Version not supported",
}

local DEFAULT_ERROR_MESSAGE = [[
    <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
    <html>
    <head>
        <meta http-equiv="Content-Type" content="text/html;charset=utf-8">
        <title>Error response</title>
    </head>
    <body>
        <h1>Error response</h1>
        <p>Error code: {{STATUS_CODE}}</p>
        <p>Message: {{STATUS_TEXT}}</p>
    </body>
    </html>
]]

local function dec2hex(dec)
    local b, k, out, i, d = 16, "0123456789ABCDEF", "", 0
    while dec > 0 do
        i=i+1
        local m = dec - math.floor(dec/b)*b
        dec, d = math.floor(dec/b), m + 1
        out = string.sub(k,d,d)..out
    end

    return out
end

local mimetype = require "mimetypes"
local class = require("lib.class").class
local Response = class()

function Response:new(client, writeHandler)
    self.headersSended = false
    self.templateFirstLine = "HTTP/1.1 {{STATUS_CODE}} {{STATUS_TEXT}}\r\n"
    self.headFirstLine = ""
    self.headers = {}
    self.status = 200
    self.filename = ""
    self.closed = false
    self.client = client
    self.writeHandler = writeHandler
    return self
end

function Response:statusCode(statusCode, statusText)
    self.status = statusCode
    self.headFirstLine = string.gsub(self.templateFirstLine, "{{STATUS_CODE}}", statusCode)
    self.headFirstLine = string.gsub(self.headFirstLine, "{{STATUS_TEXT}}", statusText or STATUS_TEXT[statusCode])
    return self
end

function Response:contentType(value)
    self.headers["Content-Type"] = value
    return self
end

function Response:addHeader(key, value)
    self.headers[key] = value
    return self
end

function Response:addHeaders(params)
    for key, value in pairs(params) do
        self.headers[key] = value
    end
    return self
end

function Response:_getHeaders()
    local headers = ""
    for key, value in pairs(self.headers) do
        headers = headers .. key .. ": " .. value .. "\r\n"
    end
    return headers
end

function Response:sendHeaders(stayOpen, body)
    if self.headersSended then
        return self
    end

    if stayOpen then
        self:addHeader("Transfer-Encoding", "chunked")
    elseif type(body) == "string" then
        self:addHeader("Content-Length", body:len())
    end

    self:addHeader("Date", os.date("!%a, %d %b %Y %H:%M:%S GMT", os.time()))

    if not self.headers["Content-Type"] then
        self:addHeader("Content-Type", "text/html")
    end

    self.client:send(self.headFirstLine .. self:_getHeaders())
    self.client:send("\r\n")
    self.headersSended = true

    return self
end

function Response:sendOnlyHeaders()
    self:sendHeaders(false, "")
    self:write("\r\n")
end

function Response:forward(path) -- NOTE this call must appear before any :write() otherwise it will be ignored
    self:statusCode(302)
    -- self.headers = {} -- reset all headers
    self:addHeader("Location", path)
    self:sendOnlyHeaders()
    return self
end

function Response:write(body, stayOpen)
    body = self.writeHandler:pluginProcessBodyData(body or "", stayOpen, self)
    self:sendHeaders(stayOpen, body)

    self.closed = not stayOpen

    if self.closed then
        self.client:send(body)
    elseif #body > 0 then
        self.client:send(dec2hex(#body).."\r\n"..body.."\r\n") -- do not send chunk with zero length because full chunk might be unconstructable with current set of data
    end

    if self.closed then
        self.client:close()
    end

    return self
end

function Response:writeFile(filename, contentType)
    local file = type(filename) == "string" and io.open(filename, "rb") or filename
    if file then
        local content = file:read("*a")
        file:close()
        self:contentType(contentType or mimetype.guess(filename or "") or "text/html")
        self:statusCode(200)
        self:write(content)
    else
        response:statusCode(404)
    end
    return self
end

function Response:writeDefaultErrorMessage(statusCode)
    self:statusCode(statusCode)
    local content = string.gsub(DEFAULT_ERROR_MESSAGE, "{{STATUS_CODE}}", statusCode)
    self:write(string.gsub(content, "{{STATUS_TEXT}}", STATUS_TEXT[statusCode]))
    return self
end

function Response:close()
    local body = self.writeHandler:pluginProcessBodyData(nil, true, self)
    if body and #body > 0 then
        self.client:send(dec2hex(#body).."\r\n"..body.."\r\n")
    end
    self.client:send("0\r\n\r\n")
    self.close = true
end

return Response
