local gumbo = require "gumbo"

local filename = assert(..., "Missing filename argument")
local file = assert(io.open(filename))
local text = file:read("*a")
file:close()
local document = assert(gumbo.parse(text))
local indent = ""

local void = {
    area = true, base = true, br = true, col = true, command = true,
    embed = true, hr = true, img = true, input = true, keygen = true,
    link = true, meta = true, param = true, source = true, track = true,
    wbr = true,
}

local function printf(...)
    io.write(string.format(...))
end

local function serialize(node)
    if node.type == "element" then
        printf('%s<%s', indent, node.tag)
        for name, value in pairs(node.attr or {}) do
            printf(' %s="%s"', name, value)
        end
        printf(">\n")
        indent = indent .. "    "
        for i = 1, #node do
            serialize(node[i])
        end
        indent = indent:sub(1, -5)
        if not void[node.tag] then
            printf("%s</%s>\n", indent, node.tag)
        end
    elseif node.type == "text" then
        printf('%s%s\n', indent, node.text)
    end
end

serialize(document.root)
