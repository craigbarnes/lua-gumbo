local gumbo = require "gumbo"
local id = assert(arg[1], "Error: arg[1] is nil; expected element id")
local document = assert(gumbo.parseFile(arg[2] or io.stdin))
local element = document:getElementById(id)

if element then
    element:remove()
end

document:serialize(io.stdout)
