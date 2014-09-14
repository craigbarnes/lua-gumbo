local gumbo = require "gumbo"

local input = [[
<div id=main class='foo bar baz etc'>
    <h1 id=heading>Title <!--comment --></h1>
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
assert(main.id == "main")
assert(main.id == main.attributes.id.value)
assert(main.className == "foo bar baz etc")
assert(main.className == main.attributes.class.value)

assert(heading.attributes[1].value == "heading")
assert(heading.attributes.id.value == "heading")
assert(heading[1].nodeName == "#text")
assert(heading[1].nodeType == document.TEXT_NODE)
assert(heading[1].data == "Title ")

assert(heading:hasChildNodes() == true)
assert(heading.childNodes.length == 2)
heading.childNodes[2]:remove()
assert(heading:hasChildNodes() == true)
assert(heading.childNodes.length == 1)
heading.childNodes[1]:remove()
assert(heading:hasChildNodes() == false)
assert(heading.childNodes.length == 0)
