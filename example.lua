local gumbo = require "gumbo"
local serialize = require "gumbo.serialize"

local filename = assert(..., "Missing filename argument")
local file = assert(io.open(filename))
local text = file:read("*a")
file:close()
local document = assert(gumbo.parse(text))

serialize(document.root)
