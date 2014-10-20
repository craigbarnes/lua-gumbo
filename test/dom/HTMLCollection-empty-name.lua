-- Manually converted to Lua from:
-- https://github.com/w3c/web-platform-tests/blob/83adac74b20a51d6cb83946830907c95d505ed1a/dom/collections/HTMLCollection-empty-name.html

local gumbo = require "gumbo"

local input = [[
<!doctype html>
<meta charset=utf-8>
<title>HTMLCollection and empty names</title>
<div id=log></div>
<div id=test>
<div class=a id></div>
<div class=a name></div>
<a class=a name></a>
</div>
]]

local document = assert(gumbo.parse(input))

do -- Empty string should not be in the collection
    local c = assert(document:getElementsByTagName("*"))
    assert(not c[""], "Named getter should return nil for empty string")
    assert(not c:namedItem(""), "namedItem should return nil for empty string")
end

do -- Empty string as a name for Element.getElementsByTagName
    local div = assert(document:getElementById("test"))
    local c = assert(div:getElementsByTagName("*"))
    assert(not c[""], "Named getter should return nil for empty string")
    assert(not c:namedItem(""), "namedItem should return nil for empty string")
end

do -- Empty string as a name for Element.children
    local div = assert(document:getElementById("test"))
    local c = assert(div.children)
    assert(not c[""], "Named getter should return nil for empty string")
    assert(not c:namedItem(""), "namedItem should return nil for empty string")
end

do -- Empty string as a name for Document.getElementsByClassName
    local c = assert(document:getElementsByClassName("a"))
    assert(not c[""], "Named getter should return nil for empty string")
    assert(not c:namedItem(""), "namedItem should return nil for empty string")
end

do -- Empty string as a name for Element.getElementsByClassName
    local div = assert(document:getElementById("test"))
    local c = assert(div:getElementsByClassName("a"))
    assert(not c[""], "Named getter should return nil for empty string")
    assert(not c:namedItem(""), "namedItem should return nil for empty string")
end

--[=[TODO:
test(function() {
var c = document.getElementsByTagNameNS("http://www.w3.org/1999/xhtml", "a");
assert_false("" in c, "Empty string should not be in the collection.");
assert_equals(c[""], undefined, "Named getter should return undefined for empty string.");
assert_equals(c.namedItem(""), null, "namedItem should return null for empty string.");
}, "Empty string as a name for Document.getElementsByTagNameNS");

test(function() {
var div = document.getElementById("test");
var c = div.getElementsByTagNameNS("http://www.w3.org/1999/xhtml", "a");
assert_false("" in c, "Empty string should not be in the collection.");
assert_equals(c[""], undefined, "Named getter should return undefined for empty string.");
assert_equals(c.namedItem(""), null, "namedItem should return null for empty string.");
}, "Empty string as a name for Element.getElementsByTagNameNS");
]=]
