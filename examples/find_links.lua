local gumbo = require "gumbo"
local document = assert(gumbo.parse_file(arg[1] or io.stdin))
local elements = document:getElementsByTagName("a")

for i, element in ipairs(elements) do
    local href = element:getAttribute("href")
    if href then
        print(href)
    end
end
