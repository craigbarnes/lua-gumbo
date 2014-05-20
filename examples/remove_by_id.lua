#!/usr/bin/env lua
local gumbo = require "gumbo"
local to_html = require "gumbo.serialize.html"

--- Do a recursive, depth-first search and remove any descendant element
--- with the specified id attribute.
local function remove_element_by_id(base, id)
    local function search_and_remove(node, n)
        if node[n].type == "element" then
            if node[n].attr.id == id then
                table.remove(node, n)
            else
                -- This loop must use ipairs, to allow the use of
                -- table.remove. A numeric for loop would overrun if
                -- the length of node[n] changes during iteration.
                for i in ipairs(node[n]) do
                    search_and_remove(node[n], i)
                end
            end
        end
    end
    if base and base.type == "element" or base.type == "document" then
        for i = 1, #base do
            search_and_remove(base, i)
        end
    end
end

if not arg[1] then
    io.stderr:write(
        "Error: No element ID specified\n",
        "Usage: ", arg[0], " ELEMENT-ID [FILENAME]\n"
    )
    os.exit(1)
end

local document = assert(gumbo.parse_file(arg[2] or io.stdin))
remove_element_by_id(document, arg[1])
to_html(document, io.stdout)
