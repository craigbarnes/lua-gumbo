local Element = require "gumbo.dom.Element"
local Text = require "gumbo.dom.Text"
local Comment = require "gumbo.dom.Comment"
local util = require "gumbo.dom.util"

local Document = util.merge("Node", "NonElementParentNode", {
    type = "document",
    nodeName = "#document",
    nodeType = 9,
    contentType = "text/html",
    characterSet = "UTF-8",
    URL = "about:blank"
})

local getters = {}

function getters:documentURI()
    return self.URL
end

function getters:firstChild()
    return self.childNodes[1]
end

function getters:lastChild()
    local cnodes = self.childNodes
    return cnodes[#cnodes]
end

function getters:compatMode()
    local qmode = self.quirksMode
    if qmode == "no-quirks" or qmode == "limited-quirks" then
        return "CSS1Compat"
    else
        return "BackCompat"
    end
end

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

-- The createElement(localName) method must run the these steps:
--
-- 1. If localName does not match the Name production, throw an
--    "InvalidCharacterError" exception. (http://www.w3.org/TR/xml/#NT-Name)
-- 2. If the context object is an HTML document, let localName be
--    converted to ASCII lowercase.
-- 3. Let interface be the element interface for localName and the HTML
--    namespace.
-- 4. Return a new element that implements interface, with no attributes,
--    namespace set to the HTML namespace, local name set to localName, and
--    node document set to the context object.
--
-- <http://www.w3.org/TR/dom/#dom-document-createelement>
--
function Document:createElement(localName)
    -- TODO: Handle type(localName) ~= "string"
    if not string.find(localName, "^[A-Za-z:_][A-Za-z0-9:_.-]*$") then
        return error("InvalidCharacterError")
    end
    if self.doctype.name == "html" then -- TODO: Handle self.doctype == nil
        localName = localName:lower()
    end
    -- TODO: Set namespace and nodeDocument fields
    return setmetatable({tag = localName}, Element)
end

-- The createTextNode(data) method must return a new Text node with its
-- data set to data and node document set to the context object.
--
-- Note: No check is performed that data consists of characters that match
-- the Char production.
--
-- <http://www.w3.org/TR/dom/#dom-document-createtextnode>
--
function Document:createTextNode(data)
    return setmetatable({text = data}, Text)
end

-- The createComment(data) method must return a new Comment node with its
-- data set to data and node document set to the context object.
--
-- Note: No check is performed that data consists of characters that match the
-- Char production or that it contains two adjacent hyphens or ends with
-- a hyphen.
--
-- <http://www.w3.org/TR/dom/#dom-document-createcomment>
--
function Document:createComment(data)
    return setmetatable({text = data}, Comment)
end

return Document
