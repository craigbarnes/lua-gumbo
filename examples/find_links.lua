#!/usr/bin/env lua
local gumbo = require "gumbo"
local document = assert(gumbo.parse_file(arg[1] or io.stdin))

for node in document:walk() do
    if node.type == "element" and node.localName == "a" then
        local href = node.attributes.href
        if href then
            print(href.value)
        end
    end
end
