local util = require "gumbo.dom.util"

local Element = util.implements("Node", "ChildNode")
Element.type = "element"
Element.attributes = {}

local function attr_next(attrs, i)
    local j = i + 1
    local a = attrs[j]
    if a then
        return j, a.name, a.value, a.prefix, a.line, a.column, a.offset
    end
end

function Element:attr_iter()
    return attr_next, self.attributes or {}, 0
end

return Element
