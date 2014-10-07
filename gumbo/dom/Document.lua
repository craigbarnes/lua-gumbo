local Element = require "gumbo.dom.Element"
local Text = require "gumbo.dom.Text"
local Comment = require "gumbo.dom.Comment"
local util = require "gumbo.dom.util"
local namePattern = util.namePattern
local type, rawset, ipairs, setmetatable = type, rawset, ipairs, setmetatable
local _ENV = nil

local Document = util.merge("Node", "NonElementParentNode", "ParentNode", {
    type = "document",
    nodeName = "#document",
    nodeType = 9,
    contentType = "text/html",
    characterSet = "UTF-8",
    URL = "about:blank",
    getElementsByTagName = Element.getElementsByTagName
})

local getters = Document.getters or {}

function Document:__index(k)
    if type(k) == "number" then
        return self.childNodes[k]
    end
    local field = Document[k]
    if field then
        return field
    else
        local getter = getters[k]
        if getter then
            return getter(self)
        end
    end
end

function Document:__newindex(k, v)
    -- TODO: Create a lookup table of all readonly fields and do a
    --       single check against that.
    if not getters[k] and not Document[k] then
        rawset(self, k, v)
    end
end

function Document:createElement(localName)
    if localName:find(namePattern) then
        return setmetatable({localName = localName:lower()}, Element)
    else
        return error("InvalidCharacterError")
    end
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
