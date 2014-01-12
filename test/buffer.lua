local Buffer = require "gumbo.buffer"

local buffer = Buffer()
local str = "Hello, world!"
local len = #str

for i = 1, 10 do
    buffer:write(str, str, str)
end

assert(#buffer == len * 30)
assert(tostring(buffer) == str:rep(30))
