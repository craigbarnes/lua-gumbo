#!/usr/bin/env lua
local gumbo = require "gumbo"

--- Iterate an element node recursively, printing any href attributes found
local function find_links(node)
    if node.type == "element" then
        local href = node.attributes.href
        if href then
            print(href.value)
        end
        for i = 1, #node do
            find_links(node[i])
        end
    end
end

local document = assert(gumbo.parse_file(arg[1] or io.stdin))
find_links(document.documentElement)
