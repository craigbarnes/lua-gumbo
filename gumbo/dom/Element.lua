local util = require "gumbo.dom.util"
local Buffer = require "gumbo.Buffer"
local namePattern = util.namePattern
local type, ipairs, tostring, error = type, ipairs, tostring, error
local setmetatable = setmetatable
local _ENV = nil
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
    -- TODO: Create a lookup table of all readonly fields and do a
    --       single check against that.
    elseif not getters[k] and not Element[k] and type(K) ~= "number" then
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

function Element:setAttribute(name, value)
    if not name:find(namePattern) then
        return error("InvalidCharacterError")
    end
    local attributes = self.attributes
    if attributes[name] then
        attributes[name].value = value
    else
        local attr = {name = name, value = value}
        attributes[#attributes+1] = attr
        attributes[name] = attr
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

local function Set(t)
    local set = {}
    for i = 1, #t do set[t[i]] = true end
    return set
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

local escmap = {
    ["&"] = "&amp;",
    ["<"] = "&lt;",
    [">"] = "&gt;",
    ['"'] = "&quot;"
}

local function escape_text(text)
    return (text:gsub("[&<>]", escmap):gsub("\xC2\xA0", "&nbsp;"))
end

local function escape_attr(text)
    return (text:gsub('[&"]', escmap):gsub("\xC2\xA0", "&nbsp;"))
end

local function serialize(node, buf)
    if node.type == "element" then
        local tag = node.localName
        buf:write("<", tag)
        for i, attr in ipairs(node.attributes) do
            local ns, name, val = attr.prefix, attr.name, attr.value
            if ns and not (ns == "xmlns" and name == "xmlns") then
                buf:write(" ", ns, ":", name)
            else
                buf:write(" ", name)
            end
            if not boolattr[name] or not (val == "" or val == name) then
                buf:write('="', escape_attr(val), '"')
            end
        end
        buf:write(">")
        local children = node.childNodes
        local length = #children
        if not void[tag] then
            for i = 1, length do
                serialize(children[i], buf)
            end
            buf:write("</", tag, ">")
        end
    elseif node.type == "text" then
        if raw[node.parentNode.localName] then
            buf:write(node.data)
        else
            buf:write(escape_text(node.data))
        end
    elseif node.type == "whitespace" then
        buf:write(node.data)
    elseif node.type == "comment" then
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
