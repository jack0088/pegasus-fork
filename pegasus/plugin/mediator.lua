local class = require("lib.class").class
local Subscriber = class()
local Channel = class()
local Mediator = class()

local function uuid(obj)
    return tonumber(tostring(obj):match(":%s*[0xX]*(%x+)"), 16)
end




function Subscriber:new(fn, options)
    self.options = options or {}
    self.fn = fn
    self.channels = nil
    self.id = uuid(self)
end

function Subscriber:update(options)
    if options then
        self.fn = options.fn or self.fn
        self.options = options.options or self.options
    end
end




function Channel:new(namespace, parent)
    self.stopped = false
    self.namespace = namespace
    self.callbacks = {}
    self.topics = {} -- subchannels
    self.parent = parent
end

function Channel:addSubscriber(fn, options)
    options = options or {}
    local callback = Subscriber(fn, options)
    local priority = #self.callbacks + 1

    if options.priority
    and options.priority >= 0
    and options.priority < priority
    then
        priority = options.priority
    end

    table.insert(self.callbacks, priority, callback)

    return callback
end

function Channel:getSubscriber(id)
    for i = 1, #self.callbacks do
        local callback = self.callbacks[i]
        if callback.id == id then
            return {
                index = i,
                value = callback
            }
        end
    end

    local sub
    for _, channel in pairs(self.topics) do
        sub = channel:getSubscriber(id)
        if sub then break end
    end

    return sub
end

function Channel:setPriority(id, priority)
    local callback = self:getSubscriber(id)
    if callback.value then
        table.remove(self.callbacks, callback.index)
        table.insert(self.callbacks, priority, callback.value)
    end
end

function Channel:addTopic(namespace)
    self.topics[namespace] = Channel(namespace, self)
    return self.topics[namespace]
end

function Channel:hasTopic(namespace)
    return self.topics[namespace] and true or false
end

function Channel:getTopic(namespace)
    return self.topics[namespace] or self:addTopic(namespace)
end

function Channel:removeSubscriber(id)
    local callback = self:getSubscriber(id)
    if callback and callback.value then
        for _, channel in pairs(self.topics) do
            channel:removeSubscriber(id)
        end
        return table.remove(self.callbacks, callback.index)
    end
end

function Channel:publish(result, ...)
    for i = 1, #self.callbacks do
        local callback = self.callbacks[i]

        if not callback.options.predicate or callback.options.predicate(...) then -- if it does not have a predicate, or it does and it returns `true` then run it
            local value, continue = callback.fn(...) -- just take the first result and insert it into the result table
            if value then table.insert(result, value) end
            if not continue then return result end
        end
    end

    if self.parent then
        return self.parent:publish(result, ...)
    else
        return result
    end
end




function Mediator:new(fn, options)
    self.channel = Channel("root")
end

function Mediator:getTopic(channelNamespace)
    local channel = self.channel
    for i = 1, #channelNamespace do
        channel = channel:getTopic(channelNamespace[i])
    end
    return channel
end

function Mediator:subscribe(channelNamespace, fn, options)
    return self:getTopic(channelNamespace):addSubscriber(fn, options)
end

function Mediator:getSubscriber(id, channelNamespace)
    return self:getTopic(channelNamespace):getSubscriber(id)
end

function Mediator:unsubscribe(id, channelNamespace)
    return self:getTopic(channelNamespace):removeSubscriber(id)
end

function Mediator:publish(channelNamespace, ...)
    return self:getTopic(channelNamespace):publish({}, ...)
end

return Mediator
