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
        i = i + 1
        local m = dec - math.floor(dec / b) * b
        dec, d = math.floor(dec / b), m + 1
        out = string.sub(k, d, d) .. out
    end
    return out
end

local mimetype = require "mimetypes"
local class = require("lib.class").class
local Response = class()

function Response:new(client, write_handler)
    self.first_line_template = "HTTP/1.1 {{STATUS_CODE}} {{STATUS_TEXT}}\r\n"
    self.headers_first_line = ""
    self.headers = {}
    self.headers_sent = false
    self.filename = ""
    self.status = 200
    self.client = client
    self.connection_closed = false
    self.write_handler = write_handler
    return self
end

function Response:close()
    local body = self.write_handler:pluginProcessBodyData(nil, true, self)
    if body and #body > 0 then
        self.client:send(dec2hex(#body) .. "\r\n" .. body .. "\r\n")
    end
    self.client:send("0\r\n\r\n")
    self.close = true
end

function Response:statusCode(status_code, status_text)
    self.status = status_code
    self.headers_first_line = string.gsub(self.first_line_template, "{{STATUS_CODE}}", self.status)
    self.headers_first_line = string.gsub(self.headers_first_line, "{{STATUS_TEXT}}", status_text or STATUS_TEXT[self.status])
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

function Response:sendHeaders(body, keep_client_connected)
    if self.headers_sent then
        return self
    end

    if keep_client_connected then
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

function Response:forward(path) -- NOTE this call must appear before any :write() otherwise it will be ignored
    self:statusCode(302)
    self.headers_sent = false -- force send headers again
    self.headers = {} -- reset all headers
    self:addHeader("Location", path) -- redirect to url
    self:sendHeadersOnly()
end

function Response:write(body, keep_client_connected)
    body = self.write_handler:pluginProcessBodyData(body or "", keep_client_connected, self)

    self:sendHeaders(body, keep_client_connected)

    self.connection_closed = not keep_client_connected

    if self.connection_closed then
        self.client:send(body) -- send chunk
    elseif #body > 0 then
        self.client:send(dec2hex(#body) .. "\r\n" .. body .. "\r\n") -- do not send chunk with zero length because full chunk might be unconstructable with current set of data
    end

    if self.connection_closed then
        self.client:close()
    end

    return self
end

function Response:writeFile(file_name, content_type_value)
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
    self:statusCode(status_code)
    local content = string.gsub(DEFAULT_ERROR_MESSAGE, "{{STATUS_CODE}}", self.status)
    self:write(string.gsub(content, "{{STATUS_TEXT}}", STATUS_TEXT[self.status]))
    return self
end

return Response
