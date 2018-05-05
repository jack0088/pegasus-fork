-- This plugin unit is a rewrite of two libraries
-- [1] the general purpose http router for Lua https://luarocks.org/modules/kikito/router
-- [2] and the Pegasus router https://luarocks.org/modules/moteus/pegasus-router
-- Credit the corresponding owners
-- Rewrite 2018 (c) kontakt@herrsch.de

local COLON_BYTE = string.byte(":", 1)
local WILDCARD_BYTE = string.byte("*", 1)
local HTTP_METHODS = {"get", "post", "put", "patch", "delete", "trace", "connect", "options", "head"}

local function match_one_path(node, url, callback)
    for token in url:gmatch("[^/.]+") do
        if WILDCARD_BYTE == token:byte(1) then
            node["WILDCARD"] = {["LEAF"] = callback, ["TOKEN"] = token:sub(2)}
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
    node["LEAF"] = callback
end

local function resolve(url, node, params)
    local _, _, current_token, rest = url:find("([^/.]+)(.*)")
    if not current_token then return node["LEAF"], params end

    if node["WILDCARD"] then
        params[node["WILDCARD"]["TOKEN"]] = current_token .. rest
        return node["WILDCARD"]["LEAF"], params
    end

    if node[current_token] then
        local callback, bindings = resolve(rest, node[current_token], params)
        if callback then return callback, bindings end
    end

    for param_name, child_node in pairs(node["TOKEN"] or {}) do
        local param_value = params[param_name]
        params[param_name] = current_token or param_value -- store the value in params, resolve tail url

        local callback, bindings = resolve(rest, child_node, params)
        if callback then return callback, bindings end

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

local class = require("class").class
local Router = class()

function Router:new()
    self._tree = {}
    return self
end

function Router:resolve(method, url, ...)
    local node = self._tree[method]
    if not node then return nil, ("Unknown method: %s"):format(tostring(method)) end
    return resolve(url, node, merge_params(...))
end

-- Overwrite Pegasus plugin method to use request/response with handler
function Router:newRequestResponse(request, response)
    local url = request:path()
    local method, err = request:method()
    local handler, params = self:resolve(method, url)
    if not method then return nil, err end
    if not handler then return false end
    return true, handler(request, response, params)
end

function Router:match(method, url, callback)
    if type(method) == "string" then -- always make the method to table
        method = {[method] = {[url] = callback}}
    end
    for m, routes in pairs(method) do
        for p, c in pairs(routes) do
            if not self._tree[m] then self._tree[m] = {} end
            match_one_path(self._tree[m], p, c)
        end
    end
end

-- Make http request methods (get, post, ...) be also class functions (:get(), post(), ...)
for _,method in ipairs(HTTP_METHODS) do
    Router[method] = function(self, url, callback) -- Router.get = function(self, url, callback)
        self:match(method:upper(), url, callback)  --   return self:match("GET", url, callback)
    end                                      -- end
end

-- Extend http request methods to match ANY of the HTTP_METHODS, e.g. both GET and POST
Router["any"] = function(self, url, callback)
    for _, method in ipairs(HTTP_METHODS) do
        --self:match(method:upper(), url, function(params) return callback(params, method) end)
        self:match(method:upper(), url, callback)
    end
end

return Router
