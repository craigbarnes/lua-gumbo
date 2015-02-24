local gumbo = require "gumbo"
local document = assert(gumbo.parseFile(arg[1] or io.stdin))
print(document.title)
