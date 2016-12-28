-- Prints the plain text contents of a HTML file, excluding the contents
-- of code elements. This may be useful for filtering out markup from a
-- HTML document before passing it to a spell-checker or other text
-- processing tool.

local gumbo = require "gumbo"
local document = assert(gumbo.parseFile(arg[1] or io.stdin))
local codeElements = assert(document:getElementsByTagName("code"))

for i, element in ipairs(codeElements) do
    element:remove()
end

io.write(document.body.textContent)
