local sort = table.sort
local Attributes = {}
Attributes.__index = Attributes

local function attr_next(attrs, i)
    local j = i + 1
    local a = attrs[j]
    if a then
        return j, a.name, a.value, a.namespace, a.line, a.column, a.offset
    end
end

function Attributes:copy()
    local copy = Attributes.new()
    for i = 1, #self do
        local attr = self[i]
        copy[i] = {
            name = attr.name,
            value = attr.value,
            namespace = attr.namespace
        }
    end
    return copy
end

function Attributes:iter()
    return attr_next, self, 0
end

-- TODO: Add regression test to ensure `self` is not mutated
function Attributes:iter_sorted()
    if #self > 0 then
        local copy = self:copy()
        sort(copy, function(a, b) return a.name < b.name end)
        return attr_next, copy, 0
    else
        return function() return nil end
    end
end

function Attributes.new()
    return setmetatable({}, Attributes)
end

return Attributes
