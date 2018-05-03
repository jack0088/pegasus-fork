-- modified version of https://github.com/moteus/lua-pegasus-router/blob/master/src/pegasus/plugins/router.lua
-- dependency https://luarocks.org/modules/kikito/router
-- 2018 (c) kontakt@herrsch.de

local Resolver = require "router"

local Router = {}

function Router:new()
  self.__index = Resolver:new()
  return setmetatable({}, self)
end

-- Overwrite plugin handler method to use Pegasus request/response
function Router:execute(request, response)
  local path = request:path()
  local method, err = request:method()
  local handler, params = self:resolve(method, path)
  if not method then return nil, err end
  if not handler then return false end
  return true, handler(request, response, params)
end

function Router:newRequestResponse(request, response)
  return self:execute(request, response)
end

return Router