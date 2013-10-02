package.cpath = "./?.so"
local gumbo = require "gumbo"

local input = [[
    <TITLE>Test Document</TITLE>
    <h1>Test Heading</h1>
    <p><a href=foobar.html>Quux</a></p>
    <iNValID foo="bar">abc</invalid>
    <p class=empty></p>
]]

local document = assert(gumbo.parse(input))
local root = assert(document.root)
local head, body = root[1], root[2]

assert(root.tag == "html")
assert(head.tag == "head")
assert(body.tag == "body")
assert(head[1].tag == "title")
assert(head[1][1] == "Test Document")
assert(body[1].tag == "h1")
assert(body[1][1] == "Test Heading")
assert(body[2].tag == "p")
assert(body[2][1].attr.href == "foobar.html")
assert(body[3].tag == "iNValID")
assert(body[3].attr.foo == "bar")
assert(body[3][1] == "abc")
assert(body[4].attr.class == "empty")
assert(#body[4] == 0)
assert(gumbo.parse("<h1>Hello</h1>").root[2][1][1] == "Hello")
assert(not gumbo.parse_file "non-existent-file")

print "All tests passed"
