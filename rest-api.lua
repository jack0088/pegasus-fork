local pretty = require "lib.pretty"
local route = require("icarus.plugin.router")()

local i = 0

route:get("/subscribe/:topic", function(request, response, params)
    i = i + 1
    print(i)
    response:write(i .. ": All have gone well. Here are all your headers so far:\n", true)
end)

return route