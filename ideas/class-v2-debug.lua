local pretty = require "lib.pretty"
local class = require "lib.class"

local mensch = class()
do
    local _x, _y, _something

    mensch.foobar = "foobar"

    mensch.delegate = class()
    mensch.delegate.capibara = "bara"
    mensch.delegate.get_something = function(this) return _something end
    mensch.delegate.set_something = function(this, v) _something = v end
    mensch.delegate.something = "something"

    function mensch:get_x() return _x or 0 end
    function mensch:get_y() return _y or 0 end
    function mensch:set_x(v) _x = v end
    function mensch:set_y(v) _y = v end

    function mensch:walkToPosition(x, y)
        self.x = x
        self.y = y
    end
end

mensch.x = 33

print(pretty(mensch, 6))