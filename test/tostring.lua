local gumbo = require "gumbo"
local tostring, assert = tostring, assert
local _ENV = nil

local input = [[
<!-- comment node -->
text node
<div id=div1 class=block>text</div>
<div id=div2 class='"quotes" & amps'>text</div>
]]

local document = assert(gumbo.parse(input))

do -- Element:__tostring()
    local body = assert(document.body)
    local expected = "<body>"
    assert(body.localName == "body")
    assert(body.attributes.length == 0)
    assert(tostring(body) == expected)
    assert(body ~= expected)
end

do -- Element:__tostring() with attributes
    local div1 = assert(document:getElementById("div1"))
    local expected = '<div id="div1" class="block">'
    assert(div1.localName == "div")
    assert(div1.className == "block")
    assert(tostring(div1) == expected)
    assert(div1 ~= expected)
end

do -- Element:__tostring() with attributes containing special characters
    local div2 = assert(document:getElementById("div2"))
    local expected = '<div id="div2" class="&quot;quotes&quot; &amp; amps">'
    assert(div2.localName == "div")
    assert(div2.className == '"quotes" & amps')
    assert(tostring(div2) == expected)
    assert(div2 ~= expected)
end

do -- Text:__tostring()
    local text = assert(document.body.childNodes[1])
    local expected = '#text "text node\n"'
    assert(text.type == "text")
    assert(text.data == "text node\n")
    assert(tostring(text) == expected)
    assert(text ~= expected)
end

do -- Comment:__tostring()
    local comment = assert(document.childNodes[1])
    local expected = "<!-- comment node -->"
    assert(comment.type == "comment")
    assert(comment.data == " comment node ")
    assert(tostring(comment) == expected)
    assert(comment ~= expected)
end
