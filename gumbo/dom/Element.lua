local util = require "gumbo.dom.util"
local Buffer = require "gumbo.Buffer"
local Set = require "gumbo.Set"
local NamedNodeMap = require "gumbo.dom.NamedNodeMap"
local Attr = require "gumbo.dom.Attr"
local HTMLCollection = require "gumbo.dom.HTMLCollection"
local namePattern = util.namePattern
local type, ipairs, assert = type, ipairs, assert
local tremove, rawset, setmetatable = table.remove, rawset, setmetatable
local _ENV = nil

local Element = util.merge("Node", "ChildNode", "ParentNode", {
    type = "element",
    nodeType = 1,
    namespaceURI = "http://www.w3.org/1999/xhtml",
    attributes = setmetatable({length = 0}, NamedNodeMap),
    readonly = Set{"tagName", "classList"}
})

Element.__index = util.indexFactory(Element)
Element.__newindex = util.newindexFactory(Element)

function Element:__tostring()
    return self.tagHTML
end

function Element:getElementsByTagName(localName)
    assert(type(localName) == "string")
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
    return setmetatable(collection, HTMLCollection)
end

function Element:getElementsByClassName(classNames)
    assert(type(classNames) == "string")
    local classes = {}
    local collection = {}
    local length = 0
    do
        local length = 0
        for class in classNames:gmatch("%S+") do
            length = length + 1
            classes[length] = class
        end
        classes.length = length
    end
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
    return setmetatable(collection, HTMLCollection)
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

function Element:setAttribute(name, value)
    assert(name:find(namePattern), "InvalidCharacterError")
    local attributes = self.attributes
    if attributes == Element.attributes then
        local attr = setmetatable({name = name, value = value}, Attr)
        self.attributes = setmetatable({attr, [name] = attr}, NamedNodeMap)
    else
        local attr = attributes[name]
        if attr then
            attr.value = value
        else
            attr = setmetatable({name = name, value = value}, Attr)
            attributes[#attributes+1] = attr
            attributes[name] = attr
        end
    end
end

function Element:removeAttribute(name)
    local attributes = self.attributes
    for i, attr in ipairs(attributes) do
        if attr.name == name then
            attributes[name] = nil
            tremove(attributes, i)
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
    if deep then assert(false, "NYI") end -- << TODO
    local clone = {
        localName = self.localName,
        namespaceURI = self.namespaceURI,
        prefix = self.prefix
    }
    if self:hasAttributes() then
        local attrs = {}
        for i, attr in ipairs(self.attributes) do
            local t = {
                name = attr.name,
                value = attr.value,
                prefix = attr.prefix
            }
            attrs[i] = setmetatable(t, Attr)
            attrs[attr.name] = t
        end
        clone.attributes = setmetatable(attrs, NamedNodeMap)
    end
    return setmetatable(clone, Element)
end

-- TODO: function Element:isEqualNode(node) end

-- TODO: implement all cases from http://www.w3.org/TR/dom/#dom-element-tagname
function Element.getters:tagName()
    if self.namespaceURI == "http://www.w3.org/1999/xhtml" then
        return self.localName:upper()
    else
        return self.localName
    end
end

Element.getters.nodeName = Element.getters.tagName

function Element.getters:classList()
    local class = self.attributes.class
    local list = {}
    local length = 0
    if class then
        for s in class.value:gmatch "%S+" do
            length = length + 1
            list[length] = s
            list[s] = length
        end
    end
    list.length = length
    return list
end

local void = Set {
    "area", "base", "basefont", "bgsound", "br", "col", "embed",
    "frame", "hr", "img", "input", "keygen", "link", "menuitem", "meta",
    "param", "source", "track", "wbr"
}

local raw = Set {
    "style", "script", "xmp", "iframe", "noembed", "noframes",
    "plaintext"
}

local boolattr = Set {
    "allowfullscreen", "async", "autofocus", "autoplay", "checked",
    "compact", "controls", "declare", "default", "defer", "disabled",
    "formnovalidate", "hidden", "inert", "ismap", "itemscope", "loop",
    "multiple", "multiple", "muted", "nohref", "noresize", "noshade",
    "novalidate", "nowrap", "open", "readonly", "required", "reversed",
    "scoped", "seamless", "selected", "sortable", "truespeed",
    "typemustmatch"
}

function Element.getters:isRaw()
    return raw[self.localName]
end

function Element.getters:isVoid()
    return void[self.localName]
end

local function serialize(node, buf)
    local type = node.type
    if type == "element" then
        local tag = node.localName
        buf:write(node.tagHTML)
        if not void[tag] then
            local children = node.childNodes
            for i = 1, #children do
                serialize(children[i], buf)
            end
            buf:write("</", tag, ">")
        end
    elseif type == "text" then
        if raw[node.parentNode.localName] then
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
    buffer:write("<", self.localName)
    for i, attr in ipairs(self.attributes) do
        local ns, name, val = attr.prefix, attr.name, attr.value
        if ns and not (ns == "xmlns" and name == "xmlns") then
            buffer:write(" ", ns, ":", name)
        else
            buffer:write(" ", name)
        end
        if not boolattr[name] or not (val == "" or val == name) then
            buffer:write('="', attr.escapedValue, '"')
        end
    end
    buffer:write(">")
    return buffer:tostring()
end

-- TODO:
local NYI = function() assert(false, "Not yet implemented") end
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
