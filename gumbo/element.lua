local yield = coroutine.yield
local wrap = coroutine.wrap
local sort = table.sort

local Element = {}
Element.__index = Element

local function attr_yield(attrs)
    for i = 1, #attrs do
        local a = attrs[i]
        yield(i, a.name, a.value, a.namespace, a.line, a.column, a.offset)
    end
end

function Element:attr_copy()
    local attrs = self.attr
    if attrs then
        local copy = {}
        for i = 1, #attrs do
            local attr = attrs[i]
            copy[i] = {
                name = attr.name,
                value = attr.value,
                namespace = attr.namespace
            }
        end
        return copy
    end
end

function Element:attr_iter()
    return wrap(function() attr_yield(self.attr) end)
end

function Element:attr_iter_sorted()
    if self.attr then
        local copy = self:attr_copy()
        sort(copy, function(a, b) return a.name < b.name end)
        return wrap(function() attr_yield(copy) end)
    else
        return function() return nil end
    end
end

return Element
