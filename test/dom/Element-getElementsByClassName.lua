-- Manually converted to Lua from:
-- https://github.com/w3c/web-platform-tests/blob/8c07290db5014705e7daa45e3690a54018d27bd5/dom/nodes/Element-getElementsByClassName.html

local gumbo = require "gumbo"
local ElementList = require "gumbo.dom.ElementList"
local NodeList = require "gumbo.dom.NodeList"

local input = [[
<!DOCTYPE html>
<title>Element.getElementsByClassName</title>
<div id="log"></div>
]]

local document = assert(gumbo.parse(input))

do -- getElementsByClassName should work on disconnected subtrees
    local a = document:createElement("a")
    local b = document:createElement("b")
    b.className = "foo"
    a:appendChild(b)
    local list = assert(a:getElementsByClassName("foo"))
    assert(list.length == 1)
    assert(list[1] == b)
end

do -- Interface should be correct
    local list = assert(document:getElementsByClassName("foo"))
    local mt = assert(getmetatable(list))
    assert(mt ~= NodeList)
    assert(mt == ElementList)
end
