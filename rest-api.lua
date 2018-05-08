local pretty = require "lib.pretty"
local route = require("icarus.plugin.router")()

route:get("/", function(request, response, params)
    --print("request\n" .. pretty(request:headers()))
    response:write("All have gone well. Here are all your headers so far:\n" .. pretty(request:headers()))
end)

route:get("/subscribe/:topic", function(request, response, params)
    if params.topic == "foo" then
        print("reached :foo")
        response:addHeader("Foo", "fooHeaderAdded")
        response:forward("/subscribe/bar")
    elseif params.topic == "bar" then
        print("reached :bar")
        response:addHeader("Bar", "BarHeaderAdded-FOOBAR")
        response:forward("/")
    end

    -- TODO copy headers on response.forward?!
end)

return route