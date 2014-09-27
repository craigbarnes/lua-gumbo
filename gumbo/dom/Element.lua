local util = require "gumbo.dom.util"
local getters = {}

local Element = util.merge("Node", "ChildNode", {
    type = "element",
    nodeType = 1,
    namespaceURI = "http://www.w3.org/1999/xhtml",
    attributes = {}
})

function Element:__index(k)
    if type(k) == "number" then
        return self.childNodes[k]
    end
    local field = Element[k]
    if field then
        return field
    else
        local getter = getters[k]
        if getter then
            return getter(self)
        end
    end
end

function Element:getElementsByTagName(localName)
    local collection = {} -- TODO: = setmetatable({}, HTMLCollection)
    local length = 0
    local function gather(parent)
        local childNodes = parent.childNodes
        for i = 1, #childNodes do
            local c = childNodes[i]
            if c.type == "element" then
                if c.localName == localName then
                    length = length + 1
                    collection[length] = c
                end
                gather(c)
            end
        end
    end
    gather(self)
    return collection
end

function Element:getAttribute(name)
    if type(name) == "string" then
        -- If the context object is in the HTML namespace and its node document
        -- is an HTML document, let name be converted to ASCII lowercase.
        if self.namespaceURI == "http://www.w3.org/1999/xhtml" then
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

function Element:hasAttribute(name)
    return self:getAttribute(name) and true or false
end

function Element:hasAttributes()
    return self.attributes[1] and true or false
end

function Element:cloneNode(deep)
    if deep then error "NYI" end -- << TODO
    local clone = {
        localName = self.localName,
        namespaceURI = self.namespaceURI,
        prefix = self.prefix
    }
    if self:hasAttributes() then
        local attrs = {}
        for i, attr in ipairs(self.attributes) do
            attrs[i] = {
                name = attr.name,
                value = attr.value,
                prefix = attr.prefix
            }
            attrs[attr.name] = attrs[i]
        end
        clone.attributes = attrs
    end
    return setmetatable(clone, Element)
end

function getters:firstChild()
    return self.childNodes[1]
end

function getters:lastChild()
    local cnodes = self.childNodes
    return cnodes[#cnodes]
end

-- TODO: This attribute is not readonly -- also implement a setter
function getters:id()
    local id_attr = self.attributes.id
    return id_attr and id_attr.value
end

-- TODO: This attribute is not readonly -- also implement a setter
function getters:className()
    local class_attr = self.attributes.class
    return class_attr and class_attr.value
end

-- TODO: implement all cases from http://www.w3.org/TR/dom/#dom-element-tagname
function getters:tagName()
    if self.namespaceURI == "http://www.w3.org/1999/xhtml" then
        return self.localName:upper()
    else
        return self.localName
    end
end

getters.nodeName = getters.tagName

return Element
