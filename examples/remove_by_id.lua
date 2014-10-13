local gumbo = require "gumbo"
local serialize = require "gumbo.serialize.html"
local id = assert(arg[1], "Error: arg[1] is nil; expected element id")
local document = assert(gumbo.parse_file(arg[2] or io.stdin))
local element = document:getElementById(id)

if element then
    element:remove()
end

serialize(document, io.stdout)
