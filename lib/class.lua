local unpack = table.unpack or unpack -- Lua 5.1 shim

if _VERSION:match("[%d/.]+") <= "5.1" then -- Lua 5.1 shim
    local _pairs = pairs
    function pairs(array)
        local mt = getmetatable(array)
        return (mt and (mt.__pairs or _pairs) or _pairs)(array) -- try mt.__pairs() before falling back onto pairs()
    end
end


local function class(...)
    local registry = {}
    local ancestors = {...}
    local use_strict = ancestors[#ancestors]
    local protected = type(use_strict) == "boolean" and use_strict or true -- default property policy with existing getter/setter

    if type(use_strict) == "boolean" then table.remove(ancestors) end
    if #ancestors > 0 then
        registry.get_super = function() return ancestors end
        registry.set_super = function() error("cannot assign value to a read-only property") end
    end

    function parse(property)
        local prefix = string.lower(string.sub(property, 1, 4))
        local suffix = string.sub(property, 5)
        if prefix == "get_" or prefix == "set_" then
            return string.sub(prefix, 1, -2), suffix
        end
        return nil, property
    end

    function get(object, key)
        local value = registry[key]
        local getter = registry["get_"..key]
        return getter and getter(object) or value -- invoke getter or return value
    end

    function set(object, key, value)
        local method, property = parse(key)
        if method then -- register getter/setter
            assert(type(value) == "function", string.format("%ster must be a `function` value", method))
            assert(type(registry[key]) == "nil" or protected == false, string.format("%ster has already been defined", method))
            assert(type(registry[property]) == "nil" or protected == false, string.format("cannot define %ster for property that has already been assigned a value", method))
        else
            local setter = registry["set_"..property]
            if type(setter) ~= "nil" then return setter(object, value) end -- pipe value through setter
            assert(type(registry["get_"..property]) == "nil" or protected == false, string.format("cannot assign value as setter is yet missing to the already defined getter", method))
        end
        registry[key] = value -- store value/getter/setter
        return registry[key]
    end

    function run(object)
        -- TODO
    end

    function chain(parent, child)
        -- TODO implement chaining of objects (=nodes)
        -- think about use cases - should it inherit or rather instanciate an forward copies?
        -- PS: or use the __le (>) metamethod instead of __pow (^)
    end

    function list()
        local stack = {}
        for key, value in next, registry do
            local method, property = parse(key)
            if method == "get" and type(value) == "function" then value = value() end
            if method ~= "set" then stack[property] = value end
        end
        return next, stack

        -- local _key
        -- function nxt(array)
        --     local key, value = next(array, _key)
        --     local method, property = parse(tostring(key))
        --     if key and value then _key = key else _key = nil return end
        --     if method == "get" and type(value) == "function" then value = value() end
        --     if method ~= "set" then return property, value end
        --     -- return nxt(array) -- skip
        --     -- return ">>>"..key.."<<<", value -- TODO somehow skip these ones, maybe with try repeat loop and just return all k,v at first pairs() call
        --     return key, nil
        -- end
        -- return nxt, registry
    end

    function count()
        -- TODO loop through show() and return the counted value
        return 1
    end

    return setmetatable({}, {__index = get, __newindex = set, __pow = chain, __call = run, __pairs = list}) -- __len = count
end


return class