#!/usr/bin/env lua
local gumbo = require "gumbo"
local to_html = require "gumbo.serialize.html"

if not arg[1] then
    io.stderr:write(
        "Error: No element ID specified\n",
        "Usage: ", arg[0], " ELEMENT-ID [FILENAME]\n"
    )
    os.exit(1)
end

local document = assert(gumbo.parse_file(arg[2] or io.stdin))
local element = document:getElementById(arg[1])
if element then element:remove() end
to_html(document, io.stdout)
