local class = require "lib.class".class
local get = require "lib.class".get
local set = require "lib.class".set
local printr = require "lib.pretty"

local nomnom = "nomnom"

local mensch = class()
function mensch:new()
    print("init mensch")
end
mensch.foo = get(function() return nomnom end)
-- mensch.foo = get(print, "write only prop")
mensch.foo = set(error, "this is a private get-only property")
-- mensch.foo = set(function() error("PRIVAAAasate") end)
-- mensch.foobar = "foobar"
mensch.foo = "_"

-- local peter = mensch()
-- local peter = class(mensch)()
-- local peter = class(mensch)
-- -- peter.foo = "_"

-- mensch.bla = true

-- local bimbo = class(peter)
-- print(bimbo.bla)