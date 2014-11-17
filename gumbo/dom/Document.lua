local Element = require "gumbo.dom.Element"
local NodeList = require "gumbo.dom.NodeList"
local NamedNodeMap = require "gumbo.dom.NamedNodeMap"
local Text = require "gumbo.dom.Text"
local Comment = require "gumbo.dom.Comment"
local Set = require "gumbo.Set"
local util = require "gumbo.dom.util"
local namePattern = util.namePattern
local rawset, ipairs, assert = rawset, ipairs, assert
local setmetatable = setmetatable
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
    readonly = Set {
        "characterSet", "compatMode", "contentType", "doctype",
        "documentElement", "documentURI", "implementation", "origin", "URL"
    }
})

Document.__index = util.indexFactory(Document)
Document.__newindex = util.newindexFactory(Document)

function Document:createElement(localName)
    assert(localName:find(namePattern), "InvalidCharacterError")
    return setmetatable({
      childNodes = setmetatable({}, NodeList),
      attributes = setmetatable({}, NamedNodeMap),
      localName = localName:lower()
    }, Element)
end

function Document:createTextNode(data)
    return setmetatable({data = data}, Text)
end

function Document:createComment(data)
    return setmetatable({data = data}, Comment)
end

function Document.getters:body()
    for i, node in ipairs(self.documentElement.childNodes) do
        if node.type == "element" and node.localName == "body" then
            -- gumbo parser does not initialize empty properties;
            -- empty childNodes are initialized on first get in Node
            if not node.attributes then
                node.attributes = setmetatable({}, assert(NamedNodeMap))
            end
            return node
        end
    end
end

function Document.getters:head()
    for i, node in ipairs(self.documentElement.childNodes) do
        if node.type == "element" and node.localName == "head" then
            -- gumbo parser does not initialize empty properties
            -- empty childNodes are initialized on first get in Node
            if not node.attributes then
                node.attributes = setmetatable({}, assert(NamedNodeMap))
            end
            return node
        end
    end
end

function Document.getters:documentURI()
    return self.URL
end

function Document.getters:compatMode()
    if self.quirksMode == "quirks" then
        return "BackCompat"
    else
        return "CSS1Compat"
    end
end

local constructor = {
    __call = function(self)
        return setmetatable({
            attributes = setmetatable({}, assert(NamedNodeMap)),
            childNodes = setmetatable({}, assert(NodeList))
        }, Document)
    end
}

return setmetatable(Document, constructor)
