


function node_prototype()
    local registry = {}
    local protected = true -- default property behaviour with existing getter/setter

    function split(property)
        local prefix = string.lower(string.sub(property, 1, 4))
        local suffix = string.sub(property, 5)
        if prefix == "get_" or prefix == "set_" then
            return string.sub(prefix, 1, -2), suffix
        end
        return nil, property
    end

    function pointer(method, object, property)
        if type(method) == "string" and #method > 0 then
            return string.format("%s@%s->%s", string.lower(method), object, property)
        end
        return string.format("%s->%s", object, property)
    end

    function get(object, property)
        local value = registry[pointer(nil, object, property)]
        local getter = registry[pointer("get", object, property)]
        return getter and getter(object) or value -- invoke getter or return value
    end

    function set(object, property, value)
        local method, property = split(property)
        local id = pointer(method, object, property)

        if method and #method > 0 then -- register getter/setter
            assert(type(value) == "function", "Getter/Setter handler must be a `function` value!")
            assert(type(registry[id]) == "nil" or protected == false, string.format("Can not assign value `%s` to property `%s` because property already has a %ster handler!", type(value), property, method))
        else
            local setter = registry[pointer("set", object, property)]
            if type(setter) ~= "nil" then
                return setter(object, value) -- pipe value through setter
            end
        end

        registry[id] = value -- store value/getter/setter
        return registry[id]
    end

    function show(object)
        return pairs(registry or object)
    end

    return setmetatable({}, {__index = get, __newindex = set, __pairs = show})
end





function translate(x, y)
    local node = node_prototype()

    node.foo = "foob"
    node.bar = function() return "bar" end

    node.tbl = {
        foobar = "foobar",
        age = 22,
        gender = {
            "male",
            "female",
            "trans"
        }
    }

    function node:get_x()
        return x
    end

    function node:set_x(val)
        x = val
    end
    
    return node
end


local pretty = require "lib.pretty"
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

print(pretty(test))

-- function test:get_x() return "määehh :D" end -- this sould assert
