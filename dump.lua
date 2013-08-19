package.cpath = "./?.so"
local gumbo = require "gumbo"

local document = gumbo.parse [[
    <title>Test Document</title>
    <h1>Test Heading</h1>
    <p><a href=foobar.html><strong>Bold Text</strong> etc.</a></p>
]]


local function write(text, depth, quoted)
    local indent = string.rep(" ", depth*4)
    local text = text:match("^%s*(.*)")
    local format = (quoted and #text > 1) and '%s"%s"\n' or '%s%s\n'
    io.write(string.format(format, indent, text))
end

local depth = 0
local function dump(node)
    if node.tag then
        write(node.tag, depth)
        depth = depth + 1
        for i = 1, #node do
           dump(node[i])
        end
        depth = depth - 1
    else
        write(node, depth, true)
    end
end

dump(document.root)
