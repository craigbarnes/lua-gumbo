local Element = require "gumbo.dom.Element"
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
        localName = localName:lower(),
        ownerDocument = self
    }, Element)
end

function Document:createTextNode(data)
    return setmetatable({data = data, ownerDocument = self}, Text)
end

function Document:createComment(data)
    return setmetatable({data = data, ownerDocument = self}, Comment)
end

-- https://dom.spec.whatwg.org/#concept-node-adopt
local function adopt(document, node)
    -- 1. Let oldDocument be node's node document.
    -- 2. If node's parent is not null, remove node from its parent.
    if node.parentNode ~= nil then
        node:remove()
    end
    -- 3. Set node's inclusive descendants's node document to document.
    --    (done dynamically and automatically by Node.getters.ownerDocument)
    -- 4. Run any adopting steps defined for node in other applicable
    --    specifications and pass node and oldDocument as parameters.
end

-- https://dom.spec.whatwg.org/#dom-document-adoptnode
function Document:adoptNode(node)
    -- 1. If node is a document, throw a NotSupportedError exception.
    assert(node.type ~= "document", "NotSupportedError")
    -- 2. Adopt node into the context object.
    adopt(self, node)
    -- 3. Return node.
    return node
end

function Document.getters:body()
    for i, node in ipairs(self.documentElement.childNodes) do
        if node.type == "element" and node.localName == "body" then
            return node
        end
    end
end

function Document.getters:head()
    for i, node in ipairs(self.documentElement.childNodes) do
        if node.type == "element" and node.localName == "head" then
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
    __call = function(self) return setmetatable({}, Document) end
}

return setmetatable(Document, constructor)
