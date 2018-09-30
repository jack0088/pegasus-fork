local pretty = require "lib.pretty"
local class = require "lib.class"

local mensch = class()
mensch.foobar = "foobar"

function mensch:get_x()
    return self._x
end

function mensch:set_x(v)
    self._x = v
end

mensch.x = 33

print(pretty(mensch))