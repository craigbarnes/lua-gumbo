package.cpath = "./?.so;../?.so"
local gumbo = require "gumbo"
local serpent = require "serpent"

local filename = ...
assert(filename, "A filename argument is required")

local document = assert(gumbo.parse_file(filename))
print(serpent.block(document, {comment = false, indent = "    "}))
