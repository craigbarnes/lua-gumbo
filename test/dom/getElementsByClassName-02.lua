-- Manually converted to Lua from:
-- https://github.com/w3c/web-platform-tests/blob/83adac74b20a51d6cb83946830907c95d505ed1a/dom/nodes/getElementsByClassName-02.htm

local gumbo = require "gumbo"

local input = [[
<!doctype html>
<html class="a
b">
 <head>
  <title>document.getElementsByClassName(): also simple</title>
 </head>
 <body class="a
">
  <div id="log"></div>
 </body>
</html>
]]

local document = assert(gumbo.parse(input))
local elements = assert(document:getElementsByClassName("a\n"))
assert(elements.length == 2, elements.length)
assert(elements[1] == document.documentElement)
assert(elements[2] == document.body)
