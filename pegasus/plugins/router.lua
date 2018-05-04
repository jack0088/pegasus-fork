-- This plugin unit is a rewrite of two libraries
-- [1] the general purpose http router for Lua https://luarocks.org/modules/kikito/router
-- [2] and the Pegasus router https://luarocks.org/modules/moteus/pegasus-router
-- Credit the corresponding owners
-- Rewrite 2018 (c) kontakt@herrsch.de

local COLON_BYTE = string.byte(":", 1)
local WILDCARD_BYTE = string.byte("*", 1)
local HTTP_METHODS = {"get", "post", "put", "patch", "delete", "trace", "connect", "options", "head"}

local function match_one_path(node, path, f)
  for token in path:gmatch("[^/.]+") do
    if WILDCARD_BYTE == token:byte(1) then
      node["WILDCARD"] = {["LEAF"] = f, ["TOKEN"] = token:sub(2)}
      return
    end
    if COLON_BYTE == token:byte(1) then -- if match the ":", store the param_name in "TOKEN" array.
      node["TOKEN"] = node["TOKEN"] or {}
      token = token:sub(2)
      node = node["TOKEN"]
    end
    node[token] = node[token] or {}
    node = node[token]
  end
  node["LEAF"] = f
end

local function resolve(path, node, params)
  local _, _, current_token, rest = path:find("([^/.]+)(.*)")
  if not current_token then return node["LEAF"], params end

  if node["WILDCARD"] then
    params[node["WILDCARD"]["TOKEN"]] = current_token .. rest
    return node["WILDCARD"]["LEAF"], params
  end

  if node[current_token] then
    local f, bindings = resolve(rest, node[current_token], params)
    if f then return f, bindings end
  end

  for param_name, child_node in pairs(node["TOKEN"] or {}) do
    local param_value = params[param_name]
    params[param_name] = current_token or param_value -- store the value in params, resolve tail path

    local f, bindings = resolve(rest, child_node, params)
    if f then return f, bindings end

    params[param_name] = param_value -- reset the params table.
  end

  return false
end

local function merge(destination, origin, visited)
  if type(origin) ~= "table" then return origin end
  if visited[origin] then return visited[origin] end
  if destination == nil then destination = {} end

  for k,v in pairs(origin) do
    k = merge(nil, k, visited) -- makes a copy of k
    if destination[k] == nil then
      destination[k] = merge(nil, v, visited)
    end
  end

  return destination
end

local function merge_params(...)
  local params_list = {...}
  local result, visited = {}, {}

  for i=1, #params_list do
    merge(result, params_list[i], visited)
  end

  return result
end

local Router = {}
Router.__index = Router

function Router:new()
  return setmetatable({_tree = {}}, self)
end

function Router:resolve(method, path, ...)
  local node = self._tree[method]
  if not node then return nil, ("Unknown method: %s"):format(tostring(method)) end
  return resolve(path, node, merge_params(...))
end

-- Override router class method to work with Pegasus request/response objects
function Router:execute(request, response)
  local path = request:path()
  local method, err = request:method()
  local handler, params = self:resolve(method, path)
  if not method then return nil, err end
  if not handler then return false end
  return true, handler(request, response, params)
end

-- Overwrite Pegasus plugin method to use request/response with handler
function Router:newRequestResponse(request, response)
  return self:execute(request, response)
end

function Router:match(method, path, f)
  if type(method) == "string" then -- always make the method to table
    method = {[method] = {[path] = f}}
  end
  for m, routes in pairs(method) do
    for p, f in pairs(routes) do
      if not self._tree[m] then self._tree[m] = {} end
      match_one_path(self._tree[m], p, f)
    end
  end
end

-- Make http request methods (get, post, ...) be also class functions (:get(), post(), ...)
for _,method in ipairs(HTTP_METHODS) do
  Router[method] = function(self, path, f)  -- Router.get = function(self, path, f)
    self:match(method:upper(), path, f)     --   return self:match("GET", path, f)
  end                                       -- end
end

-- Extend http request methods (get, post, ...) by this wildcard method/function (:any(), :get(), :post(), ...)
Router["any"] = function(self, path, f)     -- match any method
  for _,method in ipairs(HTTP_METHODS) do
    self:match(method:upper(), path, function(params) return f(params, method) end)
  end
end

return Router