local Node = require "gumbo.dom.Node"
local ChildNode = require "gumbo.dom.ChildNode"
local util = require "gumbo.dom.util"

local Element = util.clone(Node)
Element.__index = Element
Element.type = "element"
Element.attr = {}

Element.remove = ChildNode.remove -- TODO: use "implements" function for this

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
