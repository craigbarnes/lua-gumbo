local Node = require "gumbo.dom.Node"
local ParentNode = require "gumbo.dom.ParentNode"
local Element = require "gumbo.dom.Element"
local Text = require "gumbo.dom.Text"
local Comment = require "gumbo.dom.Comment"
local NodeList = require "gumbo.dom.NodeList"
local ElementList = require "gumbo.dom.ElementList"
local Buffer = require "gumbo.Buffer"
local Set = require "gumbo.Set"
local util = require "gumbo.dom.util"
local assertDocument = util.assertDocument
local assertNode = util.assertNode
local assertStringOrNil = util.assertStringOrNil
local assertName = util.assertName
local ipairs, assert, type = ipairs, assert, type
local setmetatable = setmetatable
local _ENV = nil

local Document = util.merge(Node, ParentNode, {
    type = "document",
    nodeName = "#document",
    nodeType = 9,
    quirksMode = "quirks",
    contentType = "text/html",
    characterSet = "UTF-8",
    URL = "about:blank",
    getElementsByTagName = Element.getElementsByTagName,
    getElementsByClassName = Element.getElementsByClassName,
    readonly = Set {
        "characterSet", "compatMode", "contentType", "doctype",
        "documentElement", "documentURI", "forms", "head", "images",
        "implementation", "links", "origin", "scripts", "URL"
    }
})

function Document:getElementById(elementId)
    assertNode(self)
    if type(elementId) == "string" then
        for node in self:walk() do
            if node.type == "element" and node.id == elementId then
                return node
            end
        end
    end
end

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
    assertStringOrNil(data)
    return setmetatable({data = data, ownerDocument = self}, Text)
end

function Document:createComment(data)
    assertDocument(self)
    assertStringOrNil(data)
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
-- TODO: function Document:importNode(node, deep)

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

function Document.getters:links()
    local collection = {}
    local length = 0
    local root = self.documentElement
    if root then
        for node in root:walk() do
            if
                node.type == "element"
                and (node.localName == "a" or node.localName == "area")
                and node:hasAttribute("href")
            then
                length = length + 1
                collection[length] = node
            end
        end
    end
    collection.length = length
    return setmetatable(collection, ElementList)
end

function Document.getters:images()
    return self:getElementsByTagName("img")
end

function Document.getters:forms()
    return self:getElementsByTagName("form")
end

function Document.getters:scripts()
    return self:getElementsByTagName("script")
end

function Document.getters:titleElement()
    local root = self.documentElement
    if root then
        for node in root:walk() do
            if node.type == "element" and node.localName == "title" then
                return node
            end
        end
    end
end

function Document.getters:title()
    local titleElement = self.titleElement
    if titleElement and titleElement:hasChildNodes() == true then
        local buffer = Buffer()
        for i, node in ipairs(titleElement.childNodes) do
            if node.nodeName == "#text" then
                buffer:write(node.data)
            end
        end
        local whitespace = "[ \t\n\f\r]+"
        local trim = "^[ \t\n\f\r]*(.-)[ \t\n\f\r]*$"
        return (buffer:tostring():gsub(whitespace, " "):gsub(trim, "%1"))
    end
    return ""
end

function Document.setters:title(value)
    assertStringOrNil(value)
    if self.documentElement.namespaceURI == "http://www.w3.org/1999/xhtml" then
        local element = self.titleElement
        if not element then
            local head = self.head
            if head then
                element = head:appendChild(self:createElement("title"))
            else
                return
            end
        end
        element.textContent = value
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
