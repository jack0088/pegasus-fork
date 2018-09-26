local class = require "lib.class"

local mensch = class()
function mensch:new()
    
end

local peter = class(mensch)
function peter:new()
    mensch.new(self)
    print("init peter as mensch")
end
