local function concanate(tab, recurse, indent)
    local res = ''

    if not indent then
        indent = 0
    end

    local format_value = function(k, v, i)
        formatting = string.rep("\t", i)

        if k then
            if type(k) == "table" then
                k = '[table]'
            end
            formatting = formatting .. tostring(k) .. ": "
        end

        if not v then
            return formatting .. '(nil)'
        elseif type(v) == "table" then
            if recurse and recurse > 0 then
                return formatting .. '\n' .. concanate(v, recurse-1, i+1)
            else
                return formatting .. "<table>"
            end
        elseif type(v) == "function" then
            return formatting .. tostring(v)
        elseif type(v) == "userdata" then
            return formatting .. "<userdata>"
        elseif type(v) == "boolean" then
            if v then
                return formatting .. 'true'
            else
                return formatting .. 'false'
            end
        else
            return formatting .. tostring(v)
        end
    end

    if type(tab) == "table" then
        local first = true

        -- add the meta table.
        local mt = getmetatable(tab)
        if mt and not next(mt) == nil then
            res = res .. format_value('__metatable', mt, indent)
            first = false
        end

        -- add all values.
        -- for k, v in next, tab do
        for k, v in pairs(tab) do
            if not first then
                res = res .. '\n'
            end

            res = res .. format_value(k, v, indent)
            first = false
        end
    else
        res = res .. format_value(nil, tab, indent)
    end

    return res
end

return concanate
