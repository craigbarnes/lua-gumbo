package.cpath = "./?.so"
local gumbo = require "gumbo"

local document = gumbo.parse [[
    <title>Test Document</title>
    <h1>Test Heading</h1>
    <p><a href=foobar.html><strong>Bold Text</strong> etc.</a></p>
]]

local depth = 0

local function dump(node)
    if node.tag then
        io.write(string.format("%s%s\n", string.rep(" ", depth*4), node.tag))
        depth = depth + 1
        for i = 1, #node do
           dump(node[i])
        end
        depth = depth - 1
    else
        io.write(string.format("%s%s\n", string.rep(" ", depth*4), node))
    end
end

dump(document.root)
