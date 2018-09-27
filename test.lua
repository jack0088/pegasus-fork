local class = require "lib.class".class
local get = require "lib.class".get
local set = require "lib.class".set
local printr = require "lib.pretty"

--local omnom = "omnonom"

local mensch = class()

mensch.gaga = "om"

mensch.foobar = get(function() return mensch.gaga end)
mensch.foobar = set(function() mensch.gaga = new_value end)

-- print(mensch.gaga)

local peter = class(mensch)

peter.foobar = "hha"
print(mensch.gaga, peter.super.foobar, peter.super.foobar, peter.foobar)