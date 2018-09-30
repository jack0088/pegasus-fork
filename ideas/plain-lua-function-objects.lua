--[[
    Here's how we could try structure code completely without classes or nodes or anything else
    It's just plain tables with methods and properties
    Private variables could be used as upvalues just like ever in lua
--]]

function response(request)
    local _response = {}
    _response.request = request

    function _response:resondWithFile(path)
        -- read html file content; parse, etc.
        return "html file content"
    end

    return _response
end

local pretty = require "lib.pretty"
local res = response()
print(res:resondWithFile())
print(pretty(res))