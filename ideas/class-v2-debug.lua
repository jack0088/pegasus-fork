local pretty = require "lib.pretty"
local class = require "lib.class"

local mensch = class()
do
    local _x, _something

    mensch.foobar = "foobar"

    mensch.delegate = class()
    mensch.delegate.capibara = "bara"
    mensch.delegate.get_something = function(this) return _something end
    mensch.delegate.set_something = function(this, v) _something = v end
    mensch.delegate.something = "something"

    function mensch:get_x()
        return _x
    end

    function mensch:set_x(v)
        _x = v
    end
end

mensch.x = 33

print(pretty(mensch, 6))