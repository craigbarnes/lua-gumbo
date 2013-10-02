package.cpath = "./?.so"
local gumbo = require "gumbo"

local input = [[
    <TITLE>Test Document</TITLE>
    <h1>Test Heading</h1>
    <p><a href=foobar.html>Quux</a></p>
    <iNValID foo="bar">abc</invalid>
    <p class=empty></p>
    <!-- comment node -->
]]

local document = assert(gumbo.parse(input))
local root = assert(document.root)
local head, body = root[1], root[2]

assert(root.tag == "html")
assert(head.tag == "head")
assert(body.tag == "body")
assert(head[1].tag == "title")
assert(head[1][1].text == "Test Document")
assert(body[1].tag == "h1")
assert(body[1][1].text == "Test Heading")
assert(body[2].tag == "p")
assert(body[2][1].attr.href == "foobar.html")
assert(body[3].tag == "iNValID")
assert(body[3].attr.foo == "bar")
assert(body[3][1].text == "abc")
assert(body[4].attr.class == "empty")
assert(body[5].text == " comment node ")
assert(#root == 2)
assert(#body == 5)
assert(#body[4] == 0)
assert(document.type == "document")
assert(head.type == "element")
assert(body[5].type == "comment")
assert(type(body[1][1].text) == "string")
assert(gumbo.parse("<h1>Hello</h1>").root[2][1][1].text == "Hello")
assert(not gumbo.parse_file "non-existent-file")

print "All tests passed"
