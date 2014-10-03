local util = require "gumbo.dom.util"
local getters, setters = {}, {}

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

function Element:__newindex(k, v)
    local setter = setters[k]
    if setter then
        setter(self, v)
    else
        rawset(self, k, v)
    end
end

function Element:getElementsByTagName(localName)
    local collection = {} -- TODO: = setmetatable({}, HTMLCollection)
    local length = 0
    for node in self:walk() do
        if node.type == "element" and node.localName == localName then
            length = length + 1
            collection[length] = node
        end
    end
    collection.length = length
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

-- TODO: implement all cases from http://www.w3.org/TR/dom/#dom-element-tagname
function getters:tagName()
    if self.namespaceURI == "http://www.w3.org/1999/xhtml" then
        return self.localName:upper()
    else
        return self.localName
    end
end

function getters:classList()
    local class = self.attributes.class
    if class then
        local list = {}
        local length = 0
        for s in class.value:gmatch "%S+" do
            length = length + 1
            list[length] = s
        end
        list.length = length
        return list
    end
end

-- TODO: Move to separate ParentNode module when inheritance system is fixed
function getters:children()
    if self:hasChildNodes() then
        local collection = {}
        local length = 0
        for i, node in ipairs(self.childNodes) do
            if node.type == "element" then
                length = length + 1
                collection[length] = node
            end
        end
        collection.length = length
        return collection
    end
end

local function attr_getter(name)
    return function(self)
        local attr = self.attributes[name]
        if attr then return attr.value end
    end
end

local function attr_setter(name)
    return function(self, value)
        local attributes = self.attributes
        local attr = attributes[name]
        if attr then
            attr.value = value
        else
            attr = {name = name, value = value}
            attributes[#attributes + 1] = attr
            attributes[name] = attr
        end
    end
end

getters.nodeName = getters.tagName
getters.id = attr_getter("id")
setters.id = attr_setter("id")
getters.className = attr_getter("class")
setters.className = attr_setter("class")

return Element
