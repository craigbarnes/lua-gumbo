local gumbo = require "gumbo"

local document = assert(gumbo.parse [[
<!DOCTYPE html>
<body>
    <div class="example">
        <ul>
            <li><a href="http://example.com/" hidden>Example.com</a></li>
            <li><a href="http://example.org/" hidden>Example.org</a></li>
        </ul>
    </div>
    <div class="example">
        <ul>
            <li><a href="http://example.com/" hidden>Example.com</a></li>
            <li><a href="http://example.org/" hidden>Example.org</a></li>
        </ul>
    </div>
</body>
]])

local divs = assert(document:getElementsByTagName("div"))
local div1 = assert(divs[1])
local div2 = assert(divs[2])

assert(not rawequal(div1, div2))
assert(div1:isEqualNode(div2))
assert(div2:isEqualNode(div1))
assert(div1:isEqualNode(div1))
assert(div2:isEqualNode(div2))

div1:setAttribute("id", "div1")
assert(not div1:isEqualNode(div2))
assert(not div2:isEqualNode(div1))

div2:setAttribute("id", "div2")
assert(not div1:isEqualNode(div2))
assert(not div2:isEqualNode(div1))

div1:removeAttribute("id")
div2:removeAttribute("id")
assert(div1:isEqualNode(div2))
assert(div2:isEqualNode(div1))

-- TODO:
-- local clone = assert(div1:cloneNode(true))
-- assert(clone:isEqualNode(div1))
-- assert(clone:isEqualNode(div2))

assert(div1.childNodes.length == div2.childNodes.length)
div1.childNodes[2]:remove()
assert(div1.childNodes.length ~= div2.childNodes.length)
assert(not div1:isEqualNode(div2))
assert(not div2:isEqualNode(div1))

div1:appendChild(div2:cloneNode())
assert(div1.childNodes.length == div2.childNodes.length)
assert(not div1:isEqualNode(div2))
assert(not div2:isEqualNode(div1))

assert(not div1:isEqualNode())
assert(not div1:isEqualNode({}))
assert(not div1:isEqualNode(55))
assert(not div1:isEqualNode(false))
assert(not div1:isEqualNode("<div1>"))
