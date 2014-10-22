local Element = require "gumbo.dom.Element"
local Text = require "gumbo.dom.Text"
local Comment = require "gumbo.dom.Comment"
local util = require "gumbo.dom.util"
local namePattern = util.namePattern
local type, rawset, ipairs, setmetatable = type, rawset, ipairs, setmetatable
local assert = assert
local _ENV = nil

local Document = util.merge("Node", "NonElementParentNode", "ParentNode", {
    type = "document",
    nodeName = "#document",
    nodeType = 9,
    contentType = "text/html",
    characterSet = "UTF-8",
    URL = "about:blank",
    getElementsByTagName = Element.getElementsByTagName,
    getElementsByClassName = Element.getElementsByClassName,
    readonly = {
        "characterSet", "compatMode", "contentType", "doctype",
        "documentElement", "documentURI", "implementation", "origin", "URL"
    }
})

local getters = Document.getters
local readonly = Document.readonly

function Document:__index(k)
    local field = Document[k]
    if field then
        return field
    end
    local getter = getters[k]
    if getter then
        return getter(self)
    end
    if type(k) == "number" then
        return self.childNodes[k]
    end
end

function Document:__newindex(k, v)
    if not readonly[k] and type(k) ~= "number" then
        rawset(self, k, v)
    end
end

function Document:createElement(localName)
    assert(localName:find(namePattern), "InvalidCharacterError")
    return setmetatable({localName = localName:lower()}, Element)
end

function Document:createTextNode(data)
    return setmetatable({data = data}, Text)
end

function Document:createComment(data)
    return setmetatable({data = data}, Comment)
end

function getters:body()
    for i, node in ipairs(self.documentElement.childNodes) do
        if node.type == "element" and node.localName == "body" then
            return node
        end
    end
end

function getters:head()
    for i, node in ipairs(self.documentElement.childNodes) do
        if node.type == "element" and node.localName == "head" then
            return node
        end
    end
end

function getters:documentURI()
    return self.URL
end

function getters:compatMode()
    if self.quirksMode == "quirks" then
        return "BackCompat"
    else
        return "CSS1Compat"
    end
end

return Document
