local gumbo = require "gumbo"
local Document = require "gumbo.dom.Document"
local DocumentType = require "gumbo.dom.DocumentType"
local DocumentFragment = require "gumbo.dom.DocumentFragment"
local Element = require "gumbo.dom.Element"
local NodeList = require "gumbo.dom.NodeList"
local AttributeList = require "gumbo.dom.AttributeList"
local Attribute = require "gumbo.dom.Attribute"
local Text = require "gumbo.dom.Text"
local Comment = require "gumbo.dom.Comment"
local assert, pcall = assert, pcall
local getmetatable, setmetatable = getmetatable, setmetatable
local _ENV = nil

local input = [[
    <!DOCTYPE html>
    <h1 id="heading">Title <!--comment --></h1>
    <template id="template">Hello</template>
]]

local document = assert(gumbo.parse(input))
local doctype = assert(document.doctype)
local fragment = assert(document:getElementById("template").content)
local element = assert(document:getElementById("heading"))
local nodelist = assert(element.childNodes)
local attributes = assert(element.attributes)
local attribute = assert(attributes.id)
local text = assert(element.childNodes[1])
local comment = assert(element.childNodes[2])

assert(getmetatable(document) == Document)
assert(getmetatable(doctype) == DocumentType)
assert(getmetatable(fragment) == DocumentFragment)
assert(getmetatable(element) == Element)
assert(getmetatable(nodelist) == NodeList)
assert(getmetatable(attributes) == AttributeList)
assert(getmetatable(attribute) == Attribute)
assert(getmetatable(text) == Text)
assert(getmetatable(comment) == Comment)

assert(not pcall(setmetatable, document, nil))
assert(not pcall(setmetatable, doctype, nil))
assert(not pcall(setmetatable, fragment, nil))
assert(not pcall(setmetatable, element, nil))
assert(not pcall(setmetatable, nodelist, nil))
assert(not pcall(setmetatable, attributes, nil))
assert(not pcall(setmetatable, attribute, nil))
assert(not pcall(setmetatable, text, nil))
assert(not pcall(setmetatable, comment, nil))
