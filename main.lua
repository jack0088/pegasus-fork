-- install Pegasus http server globally https://github.com/EvandroLG/pegasus.lua
-- run server with `lua main.lua`

-- TODO maybe have all dependencies installed locally for version control?

local pretty = require "pretty"
local pegasus = require "pegasus"
local router = require("plugins.router"):new()

local server = pegasus:new{
  plugins = {router},
  location = "~/.code/ru2/",
  port = "8888"
}

server:start(function(request, response)
  router:get('/:id', function(request, response, params)
    print("reached a REST endpoint with id", params.id)
  end)

  response:addHeader('Content-Type', 'text/plain')
  response:statusCode(200, "Hello World")
  response:write "Server is running..."

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
