require "lib.simploo"

simploo.hook:add("beforeInstancerInitClass", function(classFormat)
    local hasGettersSetters = false

    for memberName, memberData in pairs(classFormat.members) do
        if type(memberData['value']) == 'table'
            and memberName:sub(1, 12) ~= 'getterSetter' -- let's not add getters/setters ontop themselves
            and memberData['modifiers'] and memberData['modifiers']['public']
            and ((memberData['value']['set'] and type(memberData['value']['set']) == 'function')
                or (memberData['value']['get'] and type(memberData['value']['get']) == 'function')) then
            -- move the member variable under a different name and make it private
            local member = classFormat.members[memberName]
            member['modifiers']['private'] = true
            classFormat.members['getterSetter_' .. memberName] = member -- create hidden member variable
            classFormat.members[memberName] = nil -- remove the old member

            -- mark the class as needing getter/setter metamethods
            hasGettersSetters = true
        end
    end
    
    if hasGettersSetters then
        -- copy the old newIndex / index meta methods, if any.
        local prevIndex = classFormat.members.__index and classFormat.members.__index.value
        local prevNewIndex = classFormat.members.__newindex and classFormat.members.__newindex.value

        -- create a new meta index method which intercepts getter calls
        classFormat.members.__index = {
            modifiers = { meta = true },
            value = function(self, key, value)
                if self['getterSetter_' .. key] and self['getterSetter_' .. key]['get'] then
                    return self['getterSetter_' .. key]['get'](self)
                end

                -- if no getter/setter, call the original __index
                return prevIndex and prevIndex(self, key, value)
            end
        }

        -- create a new meta index method which intercepts setter calls
        classFormat.members.__newindex = {
            modifiers = {meta = true},
            value = function(self, key, value)
                if self['getterSetter_' .. key] and self['getterSetter_' .. key]['set'] then
                    return self['getterSetter_' .. key]['set'](self, value)
                end

                -- if no getter/setter, call the original __newindex
                return prevNewIndex and prevNewIndex(self, key, value)
            end
        }
    end
end)




class "TestGetterSetter" {
    meta {
        __index = function(self, key)
            return "old __index still works"
        end;
        __newindex = function(self, key, value)
            print("old __newindex still works", value)
        end;
    };

    private {
        bananna = 0
    };

    public {
        foobar = {
            get = function(self)
                return self.bananna + 100
            end;
            set = function(self, value)
                self.bananna = value - 1
            end;
        };
    };
}

local t = TestGetterSetter.new()
t.foobar = 5
print(t.foobar) --> 104  (5 - 1 + 100)

print(t.unknownvariable) --> "old __index still works"
t.unknownvariable = 5 --> "old __newindex still works   5"

print "\n\n"

-- print(t.members.getterSetter_foobar)

for k, v in pairs(t.members) do
    print(tostring(k), tostring(v))
end
