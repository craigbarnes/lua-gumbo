local gumbo = require "gumbo"
local assert = assert
local _ENV = nil

local document = assert(gumbo.parse [[
<!doctype html>
<meta charset=utf-8>
<title>ElementList Test</title>
<div id=log></div>
<div id=test>
<div class=a id></div>
<div class=a name></div>
<a class=a name></a>
</div>
]])

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

do -- ElementList:item()
    local divs = assert(document.body:getElementsByTagName("div"))
    assert(divs.length == 4)
    assert(divs:item(2).id == "test")
    assert(divs:item(4):getAttribute("class") == "a")
end
