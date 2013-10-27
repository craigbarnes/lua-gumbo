package.cpath = "./?.so"
local gumbo = require "gumbo"

local input = [[
<!doctype html>
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

assert(document.type == "document")
assert(document.name == "html")
assert(document.has_doctype == true)
assert(document.public_identifier == "")
assert(document.system_identifier == "")
assert(document.quirks_mode == "no-quirks")

assert(head.type == "element")
assert(body.type == "element")
assert(body[1][1].type == "text")
assert(body[8].type == "whitespace")
assert(body[9].type == "comment")

assert(root.tag == "html")
assert(head.tag == "head")
assert(body.tag == "body")
assert(head[1].tag == "title")
assert(body[1].tag == "h1")
assert(body[3].tag == "p")
assert(body[5].tag == "iNValID")

assert(body[3][1].attr.href == "foobar.html")
assert(body[5].attr.foo == "bar")
assert(body[7].attr.class == "empty")

assert(head[1][1].text == "Test Document")
assert(body[1][1].text == "Test Heading")
assert(body[5][1].text == "abc")
assert(body[8].text == "\n")
assert(body[9].text == " comment node ")

assert(#root == 2)
assert(#body == 10)
assert(#body[4] == 0)

assert(body[1].start_pos.line == 3)
assert(body[1].start_pos.column == 1)
assert(body[1].start_pos.offset == 45)
assert(body[1].end_pos.line == 3)
assert(body[1].end_pos.column == 17)
assert(body[1].end_pos.offset == 61)

assert(head.parse_flags == 11)
assert(body.parse_flags == 11)

assert(type(body[1][1].text) == "string")
assert(gumbo.parse("<h1>Hello</h1>").root[2][1][1].text == "Hello")

print "All tests passed"
