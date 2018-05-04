-- This function methods extend Lua tables to support inheritance and getter/setter properties.
-- Getters/Setters allow for private table properties or restricted read/write access.
-- Use `class()` to create an empty new class object
-- Use `class(Base)` to inherit/subclass from the 'Base' class object
-- Use `Klass.field = get(function() ... end)` to setup a getter (read only callback function) for the property
-- Use `Klass.field = set(function(value) ... end)` to setup a getter (write callback function) for the property
-- 2018 (c) kontakt@herrsch.de

if _VERSION:match("[%d/.]+") <= "5.1" then -- Lua version
    local _pairs = pairs
    function pairs(array)
        local mt = getmetatable(array)
        return (mt and (mt.__pairs or _pairs) or _pairs)(array)
    end
end

local wrapper = {__call = table.unpack or unpack}
local function wrap(value, permission) return setmetatable({value, tostring(permission)}, wrapper) end
local function unwrap(value, permission) if type(value) == "table" and getmetatable(value) == wrapper then return unwrap(value()) end return value, permission end -- recursive

local function get(value) return wrap(value, "get") end
local function set(value) return wrap(value, "set") end

local function class(base)
    local proxy = {}
    local stash = {}
    local getters = {}
    local setters = {}

    function traverse(array)
        return pairs(stash or array)
    end

    function copy(array) -- shallow (recursive)
        if type(array) ~= "table" then return {} end
        local properties = copy(array.super)
        for k, v in pairs(array) do
            if k ~= "super" then
                properties[k] = unwrap(v)
            end
        end
        return properties
    end
    
    function instantiate(array, ...)
        assert(type(array) == "table", string.format("attempt to inherit from invalid base `%s`", array))
        local instance = class()
        for k, v in pairs(copy(array)) do instance[k] = v end
        if instance.new then instance:new(...) end
        return instance
    end

    function index(array, property)
        return string.format("%s: %s", array, property)
    end

    function peek(array, property)
        local value = stash[property] or (stash.super and stash.super()[property])
        local id = index(array, property)
        local getter = getters[id]
        return type(getter) == "function" and getter() or value
    end

    function convert(value)
        if type(value) == "table" and not getmetatable(value) then
            return instantiate(value) -- convert table value into class instance value
        end
        return value
    end

    function poke(array, property, value)
        local value, permission = unwrap(value)
        local id = index(array, property)
        local getter, setter = getters[id], setters[id]
        local is_getter = type(getter) == "function"
        local is_setter = type(setter) == "function"
        
        assert(not permission or type(value) == "function", string.format("getter/setter property `%s` must be a function value", property))
        assert(not permission or not ((permission == "get" and is_getter) or (permission == "set" and is_setter)), string.format("attempt to redefine permission of property `%s`", property))
        
        if permission == "get" then
            getters[id] = value -- cache get method
            stash[property] = value() -- make property visible to public (e.g. pairs iterator function)
            return stash[property]
        elseif permission == "set" then
            setters[id] = value -- cache set method
            return nil
        end
        
        if is_setter then
            stash[property] = setter(convert(value)) -- update publicly visible value of a setter property
        elseif not is_getter and not is_setter then
            stash[property] = convert(value) -- assign value of a property which is not a getter or a setter
        end

        return stash[property]
    end

    poke(proxy, "super", get(function() return convert(base) end))
    return setmetatable(proxy, {__index = peek, __newindex = poke, __pairs = traverse, __call = instantiate})
end

return { -- NOTE Lua <= 5.1 does not support multiple returns, tables are the only option
    class = class,
    get = get,
    set = set
}
