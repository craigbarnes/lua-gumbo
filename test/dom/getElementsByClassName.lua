local gumbo = require "gumbo"
local assert = assert
local _ENV = nil

do -- https://github.com/w3c/web-platform-tests/blob/83adac74b20a51d6cb83946830907c95d505ed1a/dom/nodes/getElementsByClassName-01.htm
    local input = '<html class="a"><body class="a"></body></html>'
    local document = assert(gumbo.parse(input))
    local elements = assert(document:getElementsByClassName("\ta\n"))
    assert(elements.length == 2)
    assert(elements[1] == document.documentElement)
    assert(elements[2] == document.body)
end

do -- https://github.com/w3c/web-platform-tests/blob/83adac74b20a51d6cb83946830907c95d505ed1a/dom/nodes/getElementsByClassName-02.htm
    local input = '<html class="a\nb"><body class="a\n"></body></html>'
    local document = assert(gumbo.parse(input))
    local elements = assert(document:getElementsByClassName("a\n"))
    assert(elements.length == 2)
    assert(elements[1] == document.documentElement)
    assert(elements[2] == document.body)
end
