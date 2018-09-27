--[[
    This functions extend Lua tables by support for inheritance and getter/setter properties.
    Getters/Setters allow for private table properties or restricted read/write access.

    Use `class()` to create an empty new class object
    Use `class(BaseKlass)` to inherit/subclass from the 'BaseKlass' class object
    NOTE there is no need to call parent constructor manually, e.g. `ChildKlass.new() ParentKlass.new(self) end` – if you do, an instance instead of inherit class is created!
    Use `Klass.field = get(function() ... end)` to setup a getter (read only callback function) for the property
    Use `Klass.field = set(function(new_value) ... end)` to setup a getter (write callback function) for the property

    # HOW GETTERS & SETTERS WORK:

    ## MAKE READ-ONLY PROPERTIES:

    local Human = class()
    Human.can_fly = false
    Human.can_fly = set(error, "This is a read-only property!")

    print(Human.can_fly) -- false (OK)
    Human.can_fly = true -- ERROR (OK)

    ## BIND PROPERTY TO OTHER VARIABLES (possibly ones with local context):

    File: human.lua

    local hidden = false
    local Human = class(Skeleton)
    Human.visible = get(function() return not hidden end)
    Human.visible = set(function(toggle)
        assert(type(toggle) == "boolean", "Human visibility toggle must be a boolean value!")
        hidden = not toggle
    end)
    return Human

    File: main.lua

    local Human = require "Human"
    print(Human.visible)   -- true (OK) the actual value stored in variable `hidden` is `false` but we negated it in the getter
    Human.visible = true   -- (OK) will set the `hidden` variable to `false`
    Human.visible = "nope" -- ERROR (OK) because `assert` in setter kicks in
    
    2018 (c) kontakt@herrsch.de
--]]


if _VERSION:match("[%d/.]+") <= "5.1" then -- Lua version
    local _pairs = pairs
    function pairs(array)
        local mt = getmetatable(array)
        return (mt and (mt.__pairs or _pairs) or _pairs)(array)
    end
end


local unpack = table.unpack or unpack -- Lua 5.1 shim
local wrapper = {__call = unpack}

local function wrap(value, typeof)
    return setmetatable({value, tostring(typeof)}, wrapper)
end

local function unwrap(value, typeof) -- recursive
    if type(value) == "table" and getmetatable(value) == wrapper then
        return unwrap(value())
    end
    return value, typeof
end


local function handler(func, ...)
    local params = {...}
    local closure = function() func(unpack(params)) end
    local is_parameterized = (#params > 0 and type(func) == "function")
    return is_parameterized and closure or func
end

local function get(func, ...)
    return wrap(handler(func, ...), "get")
end

local function set(func, ...)
    return wrap(handler(func, ...), "set")
end


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
        for k, v in pairs(copy(array)) do instance[k] = v end -- copy properies throughout entire inheritance chain
        if instance.new then instance:new(...) end -- run parent constructor
        return instance
    end

    function index(array, property)
        return string.format("%s: %s", array, property)
    end

    function convert(value)
        if type(value) == "table" and not getmetatable(value) then
            return instantiate(value) -- convert table value into class instance value; class() values remain untouched!
        end
        return value
    end

    function peek(array, property)
        local value = stash[property] or (stash.super and stash.super()[property])
        local id = index(array, property)
        local getter = getters[id]
        return type(getter) == "function" and getter() or value
    end

    function poke(array, property, value)
        local value, typeof = unwrap(value)
        local id = index(array, property)
        local getter, setter = getters[id], setters[id]
        local is_getter = type(getter) == "function"
        local is_setter = type(setter) == "function"

        assert(not typeof or type(value) == "function", string.format("getter/setter property `%s` must be a function value", property))
        assert(not typeof or not ((typeof == "get" and is_getter) or (typeof == "set" and is_setter)), string.format("attempt to redefine typeof of property `%s`", property))
        
        if typeof == "get" then
            getters[id] = value -- cache get method
            stash[property] = value() -- make property visible to public (e.g. pairs iterator function)
            return stash[property]
        elseif typeof == "set" then
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


--[[
    NOTE that Lua 5.1 `require()` is implemented in `static int ll_require (lua_State *L)` in `loadlib.c` file.
    This function always returns 1 as number of returned values on stack.
    Means that functions can return multiple values, but files can not!
--]]

--return class, get, set
return {class = class, get = get, set = set}
