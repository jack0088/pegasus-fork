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
    [505] = "HTTP Version not supported"
}

local DEFAULT_ERROR_MESSAGE = [[
    <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
    <html>
    <head>
        <meta http-equiv="Content-Type" content="text/html;charset=utf-8">
        <title>Response Error</title>
    </head>
    <body>
        <h1>Response Error</h1>
        <p>Error Code: %s</p>
        <p>Error Message: %s</p>
    </body>
    </html>
]]

local function hexadecimal(decimal)
    local b, k, out, i, d = 16, "0123456789ABCDEF", "", 0
    while decimal > 0 do
        i = i + 1
        local m = decimal - math.floor(decimal / b) * b
        decimal, d = math.floor(decimal / b), m + 1
        out = string.sub(k, d, d) .. out
    end
    return out
end

local mimetype = require "mimetypes"
local class = require("lib.class").class
local Response = class()

function Response:new(client, write_handler)
    self.client = client
    self.connection_closed = false
    self.hook = write_handler
    self.status = 200
    self.filename = ""
    self.headers = {}
    self.headers_first_line = ""
    self.headers_sent = false
    self.response = nil
    self:statusCode(200)
    return self
end

function Response:close()
    local body = self.hook:pluginProcessBodyData(nil, true, self)
    if body and #body > 0 then
        self.client:send(hexadecimal(#body) .. "\r\n" .. body .. "\r\n")
    end
    self.client:send("0\r\n\r\n")
    self.close = true
end

function Response:statusCode(status_code, status_text)
    self.status = status_code
    self.headers_first_line = string.format("HTTP/1.1 %s %s\r\n", self.status, status_text or STATUS_TEXT[self.status])
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

function Response:addHeaders(list)
    for key, value in pairs(list) do
        self.headers[key] = value
    end
    return self
end

function Response:getHeaders()
    local headers = ""
    for key, value in pairs(self.headers) do
        headers = headers .. key .. ": " .. value .. "\r\n"
    end
    return headers
end

function Response:sendHeaders(body, keep_connected)
    if self.headers_sent then
        return self
    end

    if keep_connected then
        self:addHeader("Transfer-Encoding", "chunked")
    elseif type(body) == "string" then
        self:addHeader("Content-Length", body:len())
    end

    self:addHeader("Date", os.date("!%a, %d %b %Y %H:%M:%S GMT", os.time()))

    if not self.headers["Content-Type"] then
        self:addHeader("Content-Type", "text/html")
    end

    self.client:send(self.headers_first_line .. self:getHeaders())
    self.client:send("\r\n")
    self.headers_sent = true

    return self
end

function Response:sendHeadersOnly()
    self:sendHeaders("", false)
    self:write("\r\n")
end

function Response:forward(path)
    self:statusCode(302)
    self:addHeader("Location", path)
    self:sendHeadersOnly()
end

function Response:write(body, keep_connected)
    body = self.hook:pluginProcessBodyData(body or "", keep_connected, self)

    self:sendHeaders(body, keep_connected)

    self.connection_closed = not keep_connected

    if self.connection_closed then
        self.client:send(body) -- send chunk
    elseif #body > 0 then
        self.client:send(hexadecimal(#body) .. "\r\n" .. body .. "\r\n") -- do not send chunk with zero length because full chunk might be unconstructable with current set of data
    end

    if self.connection_closed then
        self.client:close()
    end

    return self
end

function Response:writeFile(file_name, content_type_value)
    -- TODO convert self.location before reading image with path?
    local file = type(file_name) == "string" and io.open(file_name, "rb") or file_name
    if file then
        local content = file:read("*a")
        file:close()
        self:contentType(content_type_value or mimetype.guess(file_name or "") or "text/html")
        self:statusCode(200)
        self:write(content)
    else
        response:statusCode(404)
    end
    return self
end

function Response:writeDefaultErrorMessage(status_code)
    self:statusCode(status_code or 404)
    self:write(string.format(DEFAULT_ERROR_MESSAGE, self.status, STATUS_TEXT[self.status]))
    return self
end

return Response
