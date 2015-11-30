local gumbo = require "gumbo"

local input = [[
<!doctype html>
<meta charset=utf-8>
<title>ElementList Test</title>
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
