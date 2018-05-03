-- install Pegasus http server dependency globally https://github.com/EvandroLG/pegasus.lua
-- install generic Router dependency globally https://github.com/moteus/lua-pegasus-router/blob/master/src/pegasus/plugins/router.lua
-- run server with `lua main.lua`

-- TODO finish plugin in plugins.router
-- TODO maybe have all dependencies installed locally for version control?

local pretty = require "pretty"
local pegasus = require "pegasus"
local router  = require "plugins.router"
local route = router:new()

print(route.execute, route.newRequestResponse, route.match, route.get, router.newRequestResponse)

local server = pegasus:new{
  plugins = {route},
  location = "~/.code/ru2/",
  port = "8888"
}

server:start(function(request, response)
  route:get('/:id', function(request, response, params)
    print("reached a REST endpoint with id", params.id)
  end)

  response:addHeader('Content-Type', 'text/plain')
  response:statusCode(200, "Hello World")
  response:write "Server is running..."

  -- print(pretty(response.client))

  print(request:path(), response.request:path())

  --[[
  print "-----request-----"
  print(pretty(request))
  print "-----response-----"
  print(response.templateFirstLine)
  print(pretty(response))
  print "-----response.request-----"
  print(pretty(response.request))
  print "-----response.headers-----"
  print(pretty(response.headers))
  print "\n"
  --]]
end)
