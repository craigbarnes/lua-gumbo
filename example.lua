package.cpath = "./?.so"
local gumbo = require "gumbo"
local indent = ""

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

local function dump(node)
    if node.type == "element" then
        io.write(string.format('%s%s\n', indent, node.tag))
        indent = indent .. "    "
        for i = 1, #node do
           dump(node[i])
        end
        indent = indent:sub(1, -5)
    elseif node.type == "text" then
        io.write(string.format('%s"%s"\n', indent, node.text))
    end
end

dump(document.root)
