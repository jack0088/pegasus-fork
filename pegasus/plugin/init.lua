local lfs = require "lfs"
local class = require("lib.class").class
local Request = require "pegasus.request"
local Response = require "pegasus.response"
local Hook = class()

local function ternary(condition, t, f)
    if condition then return t else return f end
end

function Hook:new(callback, location, plugins)
    self.callback = callback
    self.location = location or ""
    self.plugins = plugins or {}
    self:pluginAlterRequestResponseMetatable()
    return self
end

function Hook:pluginAlterRequestResponseMetatable()
    for _, plugin in ipairs(self.plugins) do
        if plugin.alterRequestResponseMetaTable then
            local stop = plugin:alterRequestResponseMetaTable(Request, Response)
            if stop then
                return stop
            end
        end
    end
end

function Hook:pluginNewRequestResponse(request, response)
    for _, plugin in ipairs(self.plugins) do
        if plugin.newRequestResponse then
            local stop = plugin:newRequestResponse(request, response)
            if stop then
                return stop
            end
        end
    end
end

function Hook:pluginBeforeProcess(request, response)
    for _, plugin in ipairs(self.plugins) do
        if plugin.beforeProcess then
            local stop = plugin:beforeProcess(request, response)
            if stop then
                return stop
            end
        end
    end
end

function Hook:pluginAfterProcess(request, response)
    for _, plugin in ipairs(self.plugins) do
        if plugin.afterProcess then
            local stop = plugin:afterProcess(request, response)
            if stop then
                return stop
            end
        end
    end
end

function Hook:pluginProcessFile(request, response, filename)
    for _, plugin in ipairs(self.plugins) do
        if plugin.processFile then
            local stop = plugin:processFile(request, response, filename)
            if stop then
                return stop
            end
        end
    end
end

function Hook:pluginProcessBodyData(data, stayOpen, response)
    local localData = data
    for _, plugin in ipairs(self.plugins) do
        if plugin.processBodyData then
            localData = plugin:processBodyData(localData, stayOpen, response.request, response)
        end
    end
    return localData
end

function Hook:processRequestResponse(port, client)
    local request = Request(port, client)
    if not request:method() then
        client:close() -- do not respond to invalid requests, just close connection
        return
    end

    local response = Response(client, self)
    response.request = request

    local stop = self:pluginNewRequestResponse(request, response)
    if stop then
        return
    end

    if self.callback then
        -- response:statusCode(200)
        -- response.headers = {["Content-Type"] = "text/html"} -- clear and :addHeader
        self.callback(request, response)
    end

    if response.status == 404 then
        response:writeDefaultErrorMessage(404)
    end
end

return Hook
