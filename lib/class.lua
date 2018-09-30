local unpack = table.unpack or unpack -- Lua 5.1 shim

if _VERSION:match("[%d/.]+") <= "5.1" then -- Lua 5.1 shim
    local _pairs = pairs
    function pairs(array)
        local mt = getmetatable(array)
        return (mt and (mt.__pairs or _pairs) or _pairs)(array) -- try mt.__pairs() before falling back onto pairs()
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
            assert(type(registry[property]) == "nil" or protected == false, string.format("can not define %ster for property that has already been assigned a value", method))
        else
            local setter = registry["set_"..property]
            if type(setter) ~= "nil" then return setter(object, value) end -- pipe value through setter
            assert(type(registry["get_"..property]) == "nil" and type(registry["set_"..property]) == "nil" or protected == false, string.format("can not assign value as %ster has already been defined", method))
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

    function show()
        local key, value

        function list()
            key, value = next(registry, key)

            if not (key and value) then
                key, value = nil, nil -- reset
                return -- iterator finished
            end

            local method, property = parse(key)

            if method then
                if method == "get" then
                    return property, value() -- key without method prefix; value as returned by getter
                end
                return list() -- skip setter
            end

            return key, value
        end

        return list
    end

    return setmetatable({}, {__index = get, __newindex = set, __pow = chain, __call = run, __pairs = show})
end


return class