package.cpath = "./?.so"
local gumbo = require "gumbo"
local serpent = require "serpent"

local output = gumbo.parse [[
    <title>Test Document</title>
    <h1>Test heading</h1>
    <p><a href=foobar.html>Quux</a></p>
]]

print(serpent.block(output))
