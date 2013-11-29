local gumbo = require "gumbo"
local to_table = require "gumbo.serialize".to_table

local input = [[
<!doctype html>
<!-- document.root isn't always document[1] -->
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
assert(document.root == document[2])

assert(head.type == "element")
assert(body.type == "element")
assert(body[1][1].type == "text")
assert(body[8].type == "whitespace")
assert(document[1].type == "comment")
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
assert(body[1].attr == nil)

assert(head[1][1].text == "Test Document")
assert(body[1][1].text == "Test Heading")
assert(body[5][1].text == "abc")
assert(body[6].text == "\n\t")
assert(body[8].text == "\n")
assert(body[9].text == " comment node ")

assert(#document == 2)
assert(#root == 2)
assert(#body == 10)
assert(#body[1] == 1)
assert(#body[4] == 0)
assert(#body[7] == 0)

local tab8 = body[7]
local tab4 = assert(gumbo.parse(input, 4)).root[2][7]
local offset_start = input:find("<p class=empty>", 1, true) - 1
local offset_end = input:find("</p>", offset_start, true) - 1
assert(tab8.start_pos.line == 7)
assert(tab4.start_pos.line == 7)
assert(tab8.end_pos.line == 7)
assert(tab4.end_pos.line == 7)
assert(tab8.start_pos.column == 8)
assert(tab4.start_pos.column == 4)
assert(tab8.end_pos.column == 8 + offset_end - offset_start)
assert(tab4.end_pos.column == 4 + offset_end - offset_start)
assert(tab8.start_pos.offset == offset_start)
assert(tab4.start_pos.offset == offset_start)
assert(tab8.end_pos.offset == offset_end)
assert(tab4.end_pos.offset == offset_end)

assert(body[1][1].line == 4)
assert(body[1][1].column == 5)
assert(body[1][1].offset == input:find("Test Heading", 1, true) - 1)

assert(head.parse_flags == 11)
assert(body.parse_flags == 11)

assert(type(gumbo.parse_file) == "function")

-- Check that stack doesn't overflow when pushing very deeply nested elements.
-- Correct use of luaL_checkstack() should prevent this for the C module.
assert(gumbo.parse(string.rep("<div>", 500)))

do -- Check that serialized tables are loadable
    local s = assert(to_table(document))
    local f = assert(load("return " .. s, nil, "t"))
    local t = assert(f())
    assert(t.has_doctype == true)
end

print "All tests passed"
