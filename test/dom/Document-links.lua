local gumbo = require "gumbo"
local assert = assert
local _ENV = nil

local document = assert(gumbo.parse [[
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" lang="en" xml:lang="en">
<head>
    <meta charset="utf-8"/>
    <title>Document.links Test</title>
    <script>foo = true</script>
    <script>bar = false</script>
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
    <img src="http://example.com/img.png" alt="Example Image"/>
    <form action="/search" method="GET" name="form">
        <input type="text" title="Search" name="text">
    </form>
</body>
</html>
]])

do
    local links = assert(document.links)
    assert(links.length == 5)
    assert(links[1].attributes.href.value == "http://example.com/")
    assert(links[2].attributes.href.value == "http://example.org/")
    assert(links[3].attributes.href.value == "foo.html")
    assert(links[4].attributes.href.value == "bar.html")
    assert(links[5].attributes.href.value == "area.html")
    assert(links:namedItem("foo") == links[3])
    assert(links:namedItem("bar") == links[4])
end

do
    local scripts = assert(document.scripts)
    assert(scripts.length == 2)
    assert(scripts[1].textContent == "foo = true")
    assert(scripts[2].textContent == "bar = false")
end

do
    local images = assert(document.images)
    assert(images.length == 1)
    assert(images[1]:getAttribute("src") == "http://example.com/img.png")
    assert(images[1]:getAttribute("alt") == "Example Image")
end

do
    local forms = assert(document.forms)
    assert(forms.length == 1)
    assert(forms[1]:getAttribute("method") == "GET")
    local input = assert(forms[1].firstElementChild)
    assert(input:getAttribute("type") == "text")
    assert(input:getAttribute("title") == "Search")
end
