local Element = {}
Element.__index = Element

-- Element nodes with attributes have an `attr` table added by the tree
-- constructor. Those without attributes share a default, empty table
-- via the metatable, to avoid the need for nil-checking in client code.
Element.attr = {}

local function attr_next(attrs, i)
    local j = i + 1
    local a = attrs[j]
    if a then
        return j, a.name, a.value, a.namespace, a.line, a.column, a.offset
    end
end

function Element:attr_iter()
    return attr_next, self.attr or {}, 0
end


return Element
