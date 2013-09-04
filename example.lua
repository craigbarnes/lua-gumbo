package.cpath = "./?.so"
local gumbo = require "gumbo"

local document = assert(gumbo.parse_file "test.html")
local depth = 1

local function write(text, depth, quoted)
    local indent = string.rep(" ", depth*4)
    local text = text:match("^%s*(.*)")
    local format = (quoted and #text > 1) and '%s"%s"\n' or '%s%s\n'
    io.write(string.format(format, indent, text))
end

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
