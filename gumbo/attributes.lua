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

function Attributes:iter()
    return attr_next, self, 0
end

function Attributes.new()
    return setmetatable({}, Attributes)
end

return Attributes
