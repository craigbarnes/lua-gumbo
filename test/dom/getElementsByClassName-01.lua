-- Manually converted to Lua from:
-- https://github.com/w3c/web-platform-tests/blob/83adac74b20a51d6cb83946830907c95d505ed1a/dom/nodes/getElementsByClassName-01.htm

local gumbo = require "gumbo"

local input = [[<!doctype html><html class="a"><head><title>document.getElementsByClassName(): simple</title></head><body class="a"><div id="log"></div></body></html>]]

local document = assert(gumbo.parse(input))
local elements = assert(document:getElementsByClassName("\ta\n"))
local count = 0
for node in document:walk() do
  count = 1 + count
end
assert(count == 6, count)
assert(elements.length == 2, elements.length)
assert(elements[1] == document.documentElement)
assert(elements[2] == document.body)
