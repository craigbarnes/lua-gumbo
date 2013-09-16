package.cpath = "./?.so"
local gumbo = require "gumbo"

local document = assert(gumbo.parse_file "test.html")
local root = document.root

assert(root.tag == "html")
assert(root[1][1].tag == "title")
assert(root[1][1][1] == "Test Document")
assert(root[2][1].tag == "h1")
assert(root[2][1][1] == "Test Heading")
assert(root[2][2].tag == "p")
assert(root[2][2][1].attr.href == "foobar.html")
assert(root[2][3].tag == "invalid")
assert(root[2][3].attr.foo == "bar")
assert(root[2][3][1] == "abc")

assert(not gumbo.parse_file "non-existent-file")
