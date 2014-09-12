local gumbo = require "gumbo"

local input = [[
<div id=main class='foo bar baz etc'>
    <h1 id=heading>Title</h1>
</div>
]]

local document = assert(gumbo.parse(input))
local body = assert(document.documentElement[2])
local main = assert(document:getElementById("main"))
local heading = assert(document:getElementById("heading"))

assert(document.nodeName == "#document")

assert(body.nodeName == "BODY")
assert(body.nodeType == document.ELEMENT_NODE)
assert(body.localName == "body")
assert(body.parentNode.localName == "html")

assert(main == body[1])
assert(main.nodeName == "DIV")
assert(main.nodeName == main.tagName)
assert(main:hasAttribute("class") == true)
assert(main:getAttribute("class") == "foo bar baz etc")

assert(heading.attributes[1].value == "heading")
assert(heading.attributes.id.value == "heading")
assert(heading[1].nodeName == "#text")
assert(heading[1].nodeType == document.TEXT_NODE)
assert(heading[1].data == "Title")

-- TODO:
--  #heading should be heading.length
--  heading[1] should be heading.childNodes[1]
assert(heading:hasChildNodes() == true)
assert(#heading == 1)
heading[1]:remove()
assert(heading:hasChildNodes() == false)
assert(#heading == 0)
