local util = require "gumbo.dom.util"
local Node = require "gumbo.dom.Node"
local ChildNode = require "gumbo.dom.ChildNode"
local ParentNode = require "gumbo.dom.ParentNode"
local AttributeList = require "gumbo.dom.AttributeList"
local Attribute = require "gumbo.dom.Attribute"
local ElementList = require "gumbo.dom.ElementList"
local DOMTokenList = require "gumbo.dom.DOMTokenList"
local Buffer = require "gumbo.Buffer"
local Set = require "gumbo.Set"
local constants = require "gumbo.constants"
local namespaces = constants.namespaces
local voidElements = constants.voidElements
local rcdataElements = constants.rcdataElements
local booleanAttributes = constants.booleanAttributes
local assertElement = util.assertElement
local assertNode = util.assertNode
local assertName = util.assertName
local assertString = util.assertString
local NYI = util.NYI
local type, ipairs = type, ipairs
local tremove, setmetatable = table.remove, setmetatable
local _ENV = nil

local Element = util.merge(Node, ChildNode, ParentNode, {
    type = "element",
    nodeType = 1,
    namespace = "html",
    attributes = setmetatable({length = 0}, AttributeList),
    readonly = Set{"classList", "namespaceURI", "tagName"}
})

function Element:__tostring()
    assertElement(self)
    return self.tagHTML
end

function Element:getElementsByTagName(localName)
    --TODO: should use assertElement(self), but method is shared with Document
    assertNode(self)
    assertString(localName)
    local collection = {}
    local length = 0
    if localName ~= "" then
        if localName == "*" then
            for node in self:walk() do
                if node.type == "element" then
                    length = length + 1
                    collection[length] = node
                end
            end
        else
            local htmlns = "http://www.w3.org/1999/xhtml"
            local localNameLower = localName:lower()
            for node in self:walk() do
                if node.type == "element" then
                    local ns = node.namespaceURI
                    if (ns == htmlns and node.localName == localNameLower)
                    or (ns ~= htmlns and node.localName == localName)
                    then
                        length = length + 1
                        collection[length] = node
                    end
                end
            end
        end
    end
    collection.length = length
    return setmetatable(collection, ElementList)
end

local function getClassList(class)
    local list = {}
    local length = 0
    if class then
        for s in class:gmatch "%S+" do
            if not list[s] then
                length = length + 1
                list[length] = s
                list[s] = length
            end
        end
    end
    list.length = length
    return list
end

function Element:getElementsByClassName(classNames)
    --TODO: should use assertElement(self), but method is shared with Document
    assertNode(self)
    assertString(classNames)
    local classes = getClassList(classNames)
    local collection = {}
    local length = 0
    for node in self:walk() do
        if node.type == "element" then
            local classList = node.classList
            local matches = 0
            for i, class in ipairs(classes) do
                if classList[class] then
                    matches = matches + 1
                end
            end
            if matches == classes.length then
                length = length + 1
                collection[length] = node
            end
        end
    end
    collection.length = length
    return setmetatable(collection, ElementList)
end

function Element:getAttribute(name)
    assertElement(self)
    if type(name) == "string" then
        -- If the context object is in the HTML namespace and its node document
        -- is an HTML document, let name be converted to ASCII lowercase.
        if self.namespace == "html" then
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

function Element:setAttribute(name, value)
    assertElement(self)
    assertName(name)
    assertString(value)
    local attributes = self.attributes
    if attributes == Element.attributes then
        local attr = setmetatable({name = name, value = value}, Attribute)
        self.attributes = setmetatable({attr, [name] = attr}, AttributeList)
    else
        local attr = attributes[name]
        if attr then
            attr.value = value
        else
            attr = setmetatable({name = name, value = value}, Attribute)
            attributes[#attributes+1] = attr
            attributes[name] = attr
        end
    end
end

function Element:removeAttribute(name)
    assertElement(self)
    assertString(name)
    local attributes = self.attributes
    for i, attr in ipairs(attributes) do
        if attr.name == name then
            attributes[name] = nil
            tremove(attributes, i)
        end
    end
end

function Element:hasAttribute(name)
    assertElement(self)
    return self:getAttribute(name) and true or false
end

function Element:hasAttributes()
    assertElement(self)
    return self.attributes[1] and true or false
end

function Element:cloneNode(deep)
    assertElement(self)
    if deep then NYI() end -- << TODO
    local clone = {
        localName = self.localName,
        namespace = self.namespace,
        prefix = self.prefix
    }
    if self:hasAttributes() then
        local attrs = {} -- TODO: attrs = createtable(#self.attributes, 0)
        for i, attr in ipairs(self.attributes) do
            local t = {
                name = attr.name,
                value = attr.value,
                prefix = attr.prefix
            }
            attrs[i] = setmetatable(t, Attribute)
            attrs[attr.name] = t
        end
        clone.attributes = setmetatable(attrs, AttributeList)
    end
    return setmetatable(clone, Element)
end

-- TODO: Element.prefix
-- TODO: function Element.getAttributeNS(namespace, localName)
-- TODO: function Element.setAttributeNS(namespace, name, value)
-- TODO: function Element.removeAttributeNS(namespace, localName)
-- TODO: function Element.hasAttributeNS(namespace, localName)
-- TODO: function Element.closest(selectors)
-- TODO: function Element.matches(selectors)
-- TODO: function Element.getElementsByTagNameNS(namespace, localName)

function Element.getters:namespaceURI()
    return namespaces[self.namespace]
end

-- TODO: implement all cases from http://www.w3.org/TR/dom/#dom-element-tagname
function Element.getters:tagName()
    if self.namespace == "html" then
        return self.localName:upper()
    else
        return self.localName
    end
end

Element.getters.nodeName = Element.getters.tagName

function Element.getters:classList()
    return setmetatable(getClassList(self.className), DOMTokenList)
end

local function serialize(node, buf)
    local type = node.type
    if type == "element" then
        local tag = node.localName
        buf:write("<", tag)
        for i, attr in ipairs(node.attributes) do
            local ns, name = attr.prefix, attr.name
            if ns and not (ns == "xmlns" and name == "xmlns") then
                buf:write(" ", ns, ":", name)
            else
                buf:write(" ", name)
            end
            buf:write('="', attr.escapedValue, '"')
        end
        buf:write(">")
        if not voidElements[tag] then
            local children = node.childNodes
            for i = 1, #children do
                serialize(children[i], buf)
            end
            buf:write("</", tag, ">")
        end
    elseif type == "text" then
        if rcdataElements[node.parentNode.localName] then
            buf:write(node.data)
        else
            buf:write(node.escapedData)
        end
    elseif type == "whitespace" then
        buf:write(node.data)
    elseif type == "comment" then
        buf:write("<!--", node.data, "-->")
    end
end

function Element.getters:innerHTML()
    local buffer = Buffer()
    for i, node in ipairs(self.childNodes) do
        serialize(node, buffer)
    end
    return buffer:tostring()
end

function Element.getters:outerHTML()
    local buffer = Buffer()
    serialize(self, buffer)
    return buffer:tostring()
end

function Element.getters:tagHTML()
    local buffer = Buffer()
    local tag = self.localName
    buffer:write("<", tag)
    for i, attr in ipairs(self.attributes) do
        local ns, name, val = attr.prefix, attr.name, attr.value
        if ns and not (ns == "xmlns" and name == "xmlns") then
            buffer:write(" ", ns, ":", name)
        else
            buffer:write(" ", name)
        end
        local bset = booleanAttributes[tag]
        local boolattr = (bset and bset[name]) or booleanAttributes[""][name]
        if not boolattr or not (val == "" or val == name) then
            buffer:write('="', attr.escapedValue, '"')
        end
    end
    buffer:write(">")
    return buffer:tostring()
end

-- TODO:
Element.setters.innerHTML = NYI
Element.setters.outerHTML = NYI

function Element.getters:id()
    local id = self.attributes.id
    return id and id.value
end

function Element.getters:className()
    local class = self.attributes.class
    return class and class.value
end

function Element.setters:id(value)
    self:setAttribute("id", value)
end

function Element.setters:className(value)
    self:setAttribute("class", value)
end

return Element
