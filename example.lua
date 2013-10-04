package.cpath = "./?.so"
local gumbo = require "gumbo"
local depth = 1

local document = gumbo.parse [[
<!doctype html>
<html lang="en">
    <head>
        <meta charset="utf-8">
        <title>Test</title>
    </head>
    <body>
        <h1>Hello</h1>
    </body>
</html>
]]

local function write(text, depth, quoted)
    local indent = string.rep(" ", depth*4)
    local text = text:match("^%s*(.*)")
    local format = (quoted and #text > 1) and '%s"%s"\n' or '%s%s\n'
    io.write(string.format(format, indent, text))
end

local function dump(node)
    if node.type == "element" then
        write(node.tag, depth)
        depth = depth + 1
        for i = 1, #node do
           dump(node[i])
        end
        depth = depth - 1
    elseif node.type == "text" then
        write(node.text, depth, true)
    end
end

dump(document.root)
