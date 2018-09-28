


function empty_node()
    local registry = {}
    local protected = true -- default property behaviour with existing getter or setter handlers

    function pointer(method, object, property)
        if type(method) == "string" and #method > 0 then
            return string.format("%s:%s->%s", method, object, property)
        end
        return string.format("%s->%s", object, property)
    end

    function get(object, property)
        local value = registry[pointer(nil, object, property)]
        local getter = registry[pointer("get", object, property)]
        return getter and getter() or value
    end

    function set(object, property, value)
        local method, property = string.match(property, "^([gset]*)_?(.+)")

        if method and #method > 0 then
            local id = pointer(method, object, property)
            print(value, type(registry[id]))
            assert(type(registry[id]) == nil or protected == false, string.format("Can not assign `%s` to `%s` because property already has a *protected* %ster handler", value, property, method))
            registry[id] = value -- store (non-existent) getter/setter
            return registry[id]
        end

        if type(setter) == "function" then
            local output = setter(value)
            if output then return output end
        end

        registry[pointer(nil, object, property)] = value -- store value
    end

    return setmetatable({}, {__index = get, __newindex = set})
end



function translate(x, y)
    local node = empty_node()

    node.foo = "foob"
    node.bar = function() return "bar" end

    function node:get_x()
        print("__--__->x:")
        return x
    end

    function node:set_x(val)
        print("x! <-___")
        x = val
    end

    return node
end

local test = translate(1, 2)

-- function test:get_x() return "määehh :D" end -- this sould assert

-- print(test.x)