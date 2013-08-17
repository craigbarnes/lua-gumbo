package.cpath = "./?.so"
local gumbo = require "gumbo"

local output = gumbo.parse [[
    <title>Test Document</title>
    <h1>Test Heading</h1>
    <p><a href=foobar.html>Quux</a></p>
]]

assert(output.tag == "html")
assert(output[1][1].tag == "title")
assert(output[1][1][1] == "Test Document")
assert(output[2][1].tag == "h1")
assert(output[2][1][1] == "Test Heading")
assert(output[2][3].tag == "p")
assert(output[2][3][1].attrs.href == "foobar.html")
