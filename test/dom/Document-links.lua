local gumbo = require "gumbo"
local assert = assert
local _ENV = nil

local input = [[
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" lang="en" xml:lang="en">
<head>
    <meta charset="utf-8"/>
    <title>Document.links Test</title>
</head>
<body>
    <h1 href="h1-elements-cant-have-links.html">Links</h1>
    <ul>
        <li><a href="http://example.com/">example.com</a></li>
        <li><a href="http://example.org/">example.org</a></li>
        <li><a href="foo.html" name="foo">Foo</a></li>
        <li><a href="bar.html" id="bar">Bar</a></li>
    </ul>
    <map>
        <area shape="circle" coords="200,250,25" href="area.html"/>
    </map>
</body>
</html>
]]

local document = assert(gumbo.parse(input))
local links = assert(document.links)
assert(links.length == 5)
assert(links[1].attributes.href.value == "http://example.com/")
assert(links[2].attributes.href.value == "http://example.org/")
assert(links[3].attributes.href.value == "foo.html")
assert(links[4].attributes.href.value == "bar.html")
assert(links[5].attributes.href.value == "area.html")
assert(links:namedItem("foo") == links[3])
assert(links:namedItem("bar") == links[4])
