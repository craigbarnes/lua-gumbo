local Element = require "gumbo.dom.Element"
local Text = require "gumbo.dom.Text"
local Comment = require "gumbo.dom.Comment"
local NodeList = require "gumbo.dom.NodeList"
local Buffer = require "gumbo.Buffer"
local Set = require "gumbo.Set"
local util = require "gumbo.dom.util"
local assertions = require "gumbo.dom.assertions"
local assertDocument = assertions.assertDocument
local assertNode = assertions.assertNode
local assertString = assertions.assertString
local assertNilableString = assertions.assertNilableString
local assertName = assertions.assertName
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
    assertDocument(self)
    assertName(localName)
    local t = {
        localName = localName:lower(),
        ownerDocument = self,
        childNodes = setmetatable({}, NodeList)
    }
    return setmetatable(t, Element)
end

function Document:createTextNode(data)
    assertDocument(self)
    assertNilableString(data)
    return setmetatable({data = data, ownerDocument = self}, Text)
end

function Document:createComment(data)
    assertDocument(self)
    assertNilableString(data)
    return setmetatable({data = data, ownerDocument = self}, Comment)
end

-- https://dom.spec.whatwg.org/#dom-document-adoptnode
function Document:adoptNode(node)
    assertDocument(self)
    assertNode(node)
    assert(node.type ~= "document", "NotSupportedError")
    if node.parentNode ~= nil then
        node:remove()
    end
    node.ownerDocument = nil
    return node
end

function Document:serialize(buffer)
    assertDocument(self)
    local buf = buffer or Buffer()
    for i, node in ipairs(self.childNodes) do
        local type = node.type
        if type == "element" then
            buf:write(node.outerHTML)
        elseif type == "comment" then
            buf:write("<!--", node.data, "-->")
        elseif type == "doctype" then
            buf:write("<!DOCTYPE ", node.name, ">")
        end
    end
    if buf.tostring then
        return buf:tostring()
    else
        buf:write("\n")
    end
end

-- TODO: function Document:getElementsByTagNameNS(namespace, localName)
-- TODO: function Document:createElementNS(namespace, qualifiedName)
-- TODO: function Document:createDocumentFragment()
-- TODO: function Document:createProcessingInstruction(target, data)
-- TODO: function Document:importNode(node, deep)
-- TODO: function Document:createAttribute(localName)
-- TODO: function Document:createAttributeNS(namespace, name)
-- TODO: function Document:createEvent(interface)
-- TODO: function Document:createRange()

function Document.getters:doctype()
    for i, node in ipairs(self.childNodes) do
        if node.type == "doctype" then
            return node
        end
    end
end

function Document.getters:documentElement()
    for i, node in ipairs(self.childNodes) do
        if node.type == "element" then
            return node
        end
    end
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
