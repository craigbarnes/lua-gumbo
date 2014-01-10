local sort = table.sort
local Element = {}
Element.__index = Element

local function attr_next(attrs, i)
    local j = i + 1
    local a = attrs[j]
    if a then
        return j, a.name, a.value, a.namespace, a.line, a.column, a.offset
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
    return attr_next, self.attr or {}, 0
end

function Element:attr_iter_sorted()
    if self.attr then
        local copy = self:attr_copy()
        sort(copy, function(a, b) return a.name < b.name end)
        return attr_next, copy, 0
    else
        return function() return nil end
    end
end

return Element
