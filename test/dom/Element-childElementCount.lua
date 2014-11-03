-- Manually converted to Lua from:
-- https://github.com/w3c/web-platform-tests/blob/83adac74b20a51d6cb83946830907c95d505ed1a/dom/nodes/Element-childElementCount.html

local gumbo = require "gumbo"

local input = [[
<!DOCTYPE HTML>
<meta charset=utf-8>
<title>childElementCount</title>
<h1>Test of childElementCount</h1>
<div id="log"></div>
<p id="parentEl">The result of <span id="first_element_child"><span>this</span> <span>test</span></span> is
<span id="middle_element_child" style="font-weight:bold;">given above.</span>

<span id="last_element_child" style="display:none;">fnord</span> </p>
]]

local document = assert(gumbo.parse(input))

local parentEl = assert(document:getElementById("parentEl"))
assert(parentEl.childElementCount == 3)
