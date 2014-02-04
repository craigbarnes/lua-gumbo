#!/usr/bin/env lua
local gumbo = require "gumbo"

--- Iterate an element node recursively, printing any href attributes found
local function find_links(node)
    if node.type == "element" then
        for i, name, value in node:attr_iter() do
            if name == "href" then
                print(value)
            end
        end
        for i = 1, #node do
            find_links(node[i])
        end
    end
end

local document = assert(gumbo.parse_file(arg[1] or io.stdin))
find_links(document.root)
