#!/usr/bin/env lua
local gumbo = require "gumbo"
local printf = function(...) io.stdout:write(string.format(...)) end
local filename = assert(arg[1], "No input file specified")
local document = assert(gumbo.parse_file(filename))

--- Iterate an element node recursively, printing any href attributes found
local function find_links(node)
    if node.type == "element" then
        for index, name, value, namespace, line, column in node.attr:iter() do
            if name == "href" then
                printf("%s:%d:%d: %s\n", filename, line, column, value)
            end
        end
        for i = 1, #node do
            find_links(node[i])
        end
    end
end

find_links(document.root)
