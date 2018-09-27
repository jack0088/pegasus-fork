local pretty = require "lib.pretty"

function empty_node()
    local array = {}

    function pointer(method, object, property)
        return string.format("%s:%s->%s", method, object, property)
    end

    function get(obj, prop)
        local id = pointer("get", obj, property)
        return array[prop] or (handler[id] and handler[id]())
    end

    function set(obj, prop, val)
        local method, property = string.match(prop, "^([gset]*)_?(.+)")
        if method and #method > 0 then
            local id = pointer(method, obj, property)
            handler[id] = val -- store getter
            return
        end
        array[property] = val -- store plain value
    end

    return setmetatable({}, {__index = get, __newindex = set})
end


function translate(x, y)
    local node = empty_node()

    node.foobar = "foobar"

    function node:get_x()
        print("__--__-")
        return x
    end

    function node:set_x(val)
        x = val
    end

    return node
end

local test = translate(1, 2)
print(test.x, test.foobar)