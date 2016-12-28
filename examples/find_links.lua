-- Prints a list of all hyperlinks in a document.

local gumbo = require "gumbo"
local document = assert(gumbo.parseFile(arg[1] or io.stdin))

for i, element in ipairs(document.links) do
    print(element:getAttribute("href"))
end
