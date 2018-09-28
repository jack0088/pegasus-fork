


function empty_node()
    local registry = {}
    local protected = true -- default property behaviour with existing getter/setter

    function pointer(method, object, property)
        if type(method) == "string" and #method > 0 then
            return string.format("%s@%s->%s", string.lower(method), object, property)
        end
        return string.format("%s->%s", object, property)
    end

    function get(object, property)
        local value = registry[pointer(nil, object, property)]
        local getter = registry[pointer("get", object, property)]
        return getter and getter() or value -- invoke getter or return value
    end

    function set(object, property, value)
        local method, property = string.match(property, "^([gset]*)_?(.+)")
        local id = pointer(method, object, property)

        if method and #method > 0 then -- register getter/setter
            assert(type(value) == "function", "Getter/Setter handler must be a `function` value!")
            assert(type(registry[id]) == "nil" or protected == false, string.format("Can not assign value `%s` to property `%s` because property already has a %ster handler!", type(value), property, method))
        else
            local setter = registry[pointer("set", object, property)]
            if type(setter) ~= "nil" then
                setter(value) -- pipe value through setter
            end
        end

        registry[id] = value -- store value/getter/setter
    end

    return setmetatable({}, {__index = get, __newindex = set})
end



function translate(x, y)
    local node = empty_node()

    node.foo = "foob"
    node.bar = function() return "bar" end

    function node:get_x()
        return x
    end

    function node:set_x(val)
        x = val
    end
    
    return node
end

local test = translate(1, 2)


print(test.x)
test.x = 77
print(test.x)
-- print(test.foo, test.bar)
-- test.bar = "gegegegegege"
-- test.foo = "lkasdjfklajfkld"
-- function test:get_foo() return "always foobar" end
-- function test:set_foo() error("is private") end
-- test.foo = "k"
-- print(test.foo, test.bar)

-- function test:get_x() return "määehh :D" end -- this sould assert