package.path = ""
package.cpath = "./?.so"

local gumbo = require "gumbo"

local output = gumbo.parse [[
    <title>Test Document</title>
    <h1>Test heading</h1>
]]
