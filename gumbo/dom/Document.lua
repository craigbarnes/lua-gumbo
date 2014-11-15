local Element = require "gumbo.dom.Element"
local Text = require "gumbo.dom.Text"
local Comment = require "gumbo.dom.Comment"
local Set = require "gumbo.Set"
local util = require "gumbo.dom.util"
local Buffer = require "gumbo.Buffer"
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
    return setmetatable({localName = localName:lower()}, Element)
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

function Document.getters:title()
	local title_element -- The title element of a document is the first title element in the document (in tree order), if there is one, or null otherwise.
	for node in self.documentElement:walk() do
		if node.type == "element" and node.localName == "title" then
			-- Otherwise, let value be a concatenation of the data of all the child Text nodes of the title element, in tree order
			local buffer = Buffer()
			for i, node in ipairs(node.childNodes) do
				if node.type == "text" then
					buffer:write(node.data)
				end
			end
			return buffer:tostring()
		end
	end
	-- or the empty string if the title element is null.
	return ""
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
