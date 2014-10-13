local util = require "gumbo.dom.util"
local Buffer = require "gumbo.Buffer"
local Set = require "gumbo.Set"
local NamedNodeMap = require "gumbo.dom.NamedNodeMap"
local Attr = require "gumbo.dom.Attr"
local namePattern = util.namePattern
local type, ipairs, tostring, assert = type, ipairs, tostring, assert
local tremove, rawset, setmetatable = table.remove, rawset, setmetatable
local _ENV = nil
local setters = {}

local Element = util.merge("Node", "ChildNode", "ParentNode", {
    type = "element",
    nodeType = 1,
    namespaceURI = "http://www.w3.org/1999/xhtml",
    attributes = {length = 0},
    readonly = Set{"tagName", "classList"}
})

local getters = Element.getters
local readonly = Element.readonly

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
    elseif not readonly[k] and type(k) ~= "number" then
        rawset(self, k, v)
    end
end

function Element:getElementsByTagName(localName)
    local collection = {} -- TODO: = setmetatable({}, HTMLCollection)
    local length = 0
    if not localName or localName == "" then
        collection.length = 0
        return collection
    elseif localName == "*" then
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
function getters:tagName()
    if self.namespaceURI == "http://www.w3.org/1999/xhtml" then
        return self.localName:upper()
    else
        return self.localName
    end
end

getters.nodeName = getters.tagName

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

function getters:isRaw()
    return raw[self.localName]
end

function getters:isVoid()
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

function getters:innerHTML()
    local buffer = Buffer()
    for i, node in ipairs(self.childNodes) do
        serialize(node, buffer)
    end
    return tostring(buffer)
end

function getters:outerHTML()
    local buffer = Buffer()
    serialize(self, buffer)
    return tostring(buffer)
end

function getters:tagHTML()
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
    return tostring(buffer)
end

-- TODO:
local NYI = function() assert(false, "Not yet implemented") end
setters.innerHTML = NYI
setters.outerHTML = NYI

function getters:id()
    local id = self.attributes.id
    return id and id.value
end

function getters:className()
    local class = self.attributes.class
    return class and class.value
end

function setters:id(value)
    self:setAttribute("id", value)
end

function setters:className(value)
    self:setAttribute("class", value)
end

return Element
