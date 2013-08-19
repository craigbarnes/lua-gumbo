package.cpath = "./?.so"
local gumbo = require "gumbo"

local document = gumbo.parse [[
    <title>Test Document</title>
    <h1>Test Heading</h1>
    <p><a href=foobar.html>Quux</a></p>
    <invalid foo="bar">abc</invalid>
]]

local root = document.root

assert(root.tag == "html")
assert(root[1][1].tag == "title")
assert(root[1][1][1] == "Test Document")
assert(root[2][1].tag == "h1")
assert(root[2][1][1] == "Test Heading")
assert(root[2][3].tag == "p")
assert(root[2][3][1].attrs.href == "foobar.html")
assert(root[2][5].tag == "invalid")
assert(root[2][5].attrs.foo == "bar")
assert(root[2][5][1] == "abc")
