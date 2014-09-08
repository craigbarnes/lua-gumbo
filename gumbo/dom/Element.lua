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
    return attr_next, self.attributes, 0
end

function Element:hasAttribute(name)
    if type(name) == "string" then
        -- If the context object is in the HTML namespace and its node document
        -- is an HTML document, let name be converted to ASCII lowercase.
        if self.namespace == nil --[[and self.ownerDocument.ISHTMLDOC]] then
            name = name:lower()
        end
        -- Return true if the context object has an attribute whose name is
        -- name, and false otherwise.
        return self.attributes[name] and true or false
    end
    return false
end

function Element:getAttribute(name)
    if type(name) == "string" then
        -- If the context object is in the HTML namespace and its node document
        -- is an HTML document, let name be converted to ASCII lowercase.
        if self.namespace == nil --[[and self.ownerDocument.ISHTMLDOC]] then
            name = name:lower()
        end
        -- Return the value of the first attribute in the context object's
        -- attribute list whose name is name, and null otherwise.
        local attr = self.attributes[name]
        if attr then
            return attr.value
        end
    end
end

return Element
