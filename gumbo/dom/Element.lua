local util = require "gumbo.dom.util"

-- TODO: Implement nodeName (http://www.w3.org/TR/dom/#dom-node-nodename)

local Element = util.implements("Node", "ChildNode")
Element.type = "element"
Element.nodeType = 1
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
