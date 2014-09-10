#!/usr/bin/env lua
local gumbo = require "gumbo"
local to_html = require "gumbo.serialize.html"
local id, filename = arg[1], arg[2]

if not id or id == "-h" or id == "--help" then
    io.stderr:write("Usage: ", arg[0], " ELEMENT-ID [FILENAME]\n")
    os.exit(1)
end

local document = assert(gumbo.parse_file(filename or io.stdin))
local element = document:getElementById(id)
if element then element:remove() end
to_html(document, io.stdout)
