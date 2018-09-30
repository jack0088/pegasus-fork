local unpack = table.unpack or unpack -- Lua 5.1 shim

if _VERSION:match("[%d/.]+") <= "5.1" then -- Lua 5.1 shim
    local _pairs = pairs
    function pairs(array)
        local mt = getmetatable(array)
        return (mt and (mt.__pairs or _pairs) or _pairs)(array) -- try __pairs() on table before falling back onto pairs()
    end
end

local function class(use_strict)
    local registry = {}
    local protected = type(use_strict) == "boolean" and use_strict or true -- default property policy with existing getter/setter

    function parse(property)
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
        local method, property = parse(property)
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

    return setmetatable({}, {__index = get, __newindex = set, __pairs = show, __call = run, __pow = chain})
end


return class