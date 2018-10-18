--[[

    Here's an unfinished example about how we could try to implement amulet's node system instead of the conventional class system

--]]

function object_prototype(use_strict)
    local registry = {}
    local protected = type(use_strict) == "boolean" and use_strict or true -- default property policy with existing getter/setter

    function split(property)
        local prefix = string.lower(string.sub(property, 1, 4))
        local suffix = string.sub(property, 5)
        if prefix == "get_" or prefix == "set_" then
            return string.sub(prefix, 1, -2), suffix
        end
        return nil, property
    end

    function addr(method, object, property)
        if type(method) == "string" and #method > 0 then
            return string.format("%s@%s->%s", string.lower(method), object, property)
        end
        return string.format("%s->%s", object, property)
    end

    function get(object, property)
        local value = registry[addr(nil, object, property)]
        local getter = registry[addr("get", object, property)]
        return getter and getter(object) or value -- invoke getter or return value
    end

    function set(object, property, value)
        local method, property = split(property)
        local id = addr(method, object, property)

        if method then -- register getter/setter
            assert(type(value) == "function", string.format("%ster must be a `function` value", method))
            assert(type(registry[id]) == "nil" or protected == false, string.format("%ster has already been defined", method))
            assert(type(registry[addr(nil, object, property)]) == "nil" or protected == false, string.format("can not define %ster as property has already been assigned a value", method))
        else
            local setter = registry[addr("set", object, property)]
            if type(setter) ~= "nil" then return setter(object, value) end -- pipe value through setter
            assert(type(registry[addr("get", object, property)]) == "nil" and type(registry[addr("set", object, property)]) == "nil" or protected == false, string.format("can not assign value as %ster has already been defined", method))
        end

        registry[id] = value -- store value/getter/setter
        return registry[id]
    end

    function show(object)
        -- TODO implement custom iterator that only lists properties with plain values or values that have been returned by their getters
        -- property key names must be listed de-hashed (without method type and special characters)
        -- see http://lua-users.org/wiki/GeneralizedPairsAndIpairs
        return pairs(registry or object)
    end

    function run(object)
        -- TODO
    end

    function chain(parent, child)
        -- TODO implement chaining of objects (=nodes)
        -- think about use cases - should it inherit or rather instanciate an forward copies?
        -- PS: or use the __le (>) metamethod instead of __pow (^)
    end

    return setmetatable({}, {__index = get, __newindex = set, __pow = chain, __call = run, __pairs = show})
end





function translate(x, y)
    local node = object_prototype()

    node.foo = "foob"
    node.bar = function() return "bar" end

    node.tbl = {
        foobar = "foobar",
        age = 22,
        gender = {
            "male",
            "female",
            "trans"
        },
        somethingcooool = object_prototype()
    }

    node.empty_node = object_prototype()

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


-- print(test.x)
test.x = 77
-- print(test.x)
-- print(test.foo, test.bar)
-- test.bar = "gegegegegege"
-- test.foo = "lkasdjfklajfkld"
-- function test:get_foo() return "always foobar" end
-- function test:set_foo() error("is private") end
-- test.foo = "k"
-- print(test.foo, test.bar)

function test.empty_node:get_haha()
    print("ööööööö")
end
-- test.empty_node.haha = "haha"

-- print(test.empty_node.haha)

-- print(pretty(test, 6))

-- function test:get_x() return "määehh :D" end -- this sould assert
