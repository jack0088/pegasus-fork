local function check_zlib_name(lib)
    if lib._VERSION and string.find(lib._VERSION, "lua-zlib", nil, true) then
        return "lua-zlib"
    end
    if lib._VERSION and string.find(lib._VERSION, "lzlib", nil, true) then
        return "lzlib"
    end
end

local zlib = require "zlib"
local z_lib_name = assert(check_zlib_name(zlib), "Unsupported zlib Lua binding")

local class = require("class").class
local ZlibStream = class()
local Compressor = class()

ZlibStream.NO_COMPRESSION = zlib.NO_COMPRESSION or 0
ZlibStream.BEST_SPEED = zlib.BEST_SPEED or 1
ZlibStream.BEST_COMPRESSION = zlib.BEST_COMPRESSION or 9
ZlibStream.DEFAULT_COMPRESSION = zlib.DEFAULT_COMPRESSION or -1
ZlibStream.STORE = 0
ZlibStream.DEFLATE = 8

Compressor.NO_COMPRESSION = ZlibStream.NO_COMPRESSION
Compressor.BEST_SPEED = ZlibStream.BEST_SPEED
Compressor.BEST_COMPRESSION = ZlibStream.BEST_COMPRESSION
Compressor.DEFAULT_COMPRESSION = ZlibStream.DEFAULT_COMPRESSION

if z_lib_name == "lzlib" then
    function ZlibStream:new(writer, level, method, windowBits)
        level = level or ZlibStream.DEFAULT_COMPRESSION
        method = method or ZlibStream.DEFLATE
        self.zd = assert(zlib.deflate(writer, level, method, windowBits))
        return self
    end

    function ZlibStream:write(chunk)
        assert(self.zd:write(chunk))
    end

    function ZlibStream:close()
        self.zd:close()
    end

elseif z_lib_name == "lua-zlib" then
    function ZlibStream:new(writer, level, method, windowBits)
        level = level or ZlibStream.DEFAULT_COMPRESSION
        method = method or ZlibStream.DEFLATE
        assert(method == ZlibStream.DEFLATE, "lua-zlib support only deflated method")
        self.zd = assert(zlib.deflate(level, windowBits))
        self.writer = writer
        return self
    end

    function ZlibStream:write(chunk)
        chunk = assert(self.zd(chunk))
        self.writer(chunk)
    end

    function ZlibStream:close()
        local chunk = self.zd("", "finish")
        if chunk and #chunk > 0 then self.writer(chunk) end
    end
end

function Compressor:new(options)
    self.options = options or {}
    return self
end

function Compressor:processBodyData(data, stayOpen, request, response)
    local accept_encoding

    if response.headersSended then
        accept_encoding = response.headers["Content-Encoding"] or ""
    else
        local headers = request:headers()
        accept_encoding = headers and headers["Accept-Encoding"] or ""
    end

    local accept_gzip = not not accept_encoding:find("gzip", nil, true)

    if accept_gzip and self.options.level ~= ZlibStream.NO_COMPRESSION then
        local stream = response.compress_stream
        local buffer = response.compress_buffer

        if not stream then
            local writer = function(zdata) buffer[#buffer + 1] = zdata end
            stream, buffer = ZlibStream(writer, self.options.level, nil, 31), {}
        end

        if stayOpen then
            if data == nil then
                stream:close()
                response.compress_stream = nil
                response.compress_buffer = nil
            else
                stream:write(data)
                response.compress_stream = stream
                response.compress_buffer = buffer
            end

            local compressed = table.concat(buffer)

            for i = 1, #buffer do buffer[i] = nil end

            if not response.headersSended then
                response:addHeader("Content-Encoding", "gzip")
            end

            return compressed
        end

        stream:write(data)
        stream:close()
        local compressed = table.concat(buffer)

        if #compressed < #data then
            if not response.headersSended then
                response:addHeader("Content-Encoding", "gzip")
            end
            return compressed
        end
    end

    return data
end

return Compressor
