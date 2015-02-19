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

do
    local input = [[
        <div id="example">
            <p id="p1" class="aaa bbb"/>
            <p id="p2" class="aaa ccc"/>
            <p id="p3" class="bbb ccc"/>
        </div>
    ]]
    local document = assert(gumbo.parse(input))
    local example = assert(document:getElementById('example'))
    local aaa = assert(example:getElementsByClassName('aaa'))
    local ccc_bbb = assert(example:getElementsByClassName('ccc bbb'))
    local bbb_ccc = assert(example:getElementsByClassName('bbb ccc '))
    assert(aaa.length == 2)
    assert(aaa[1].id == "p1")
    assert(aaa[2].id == "p2")
    assert(ccc_bbb.length == 1)
    assert(ccc_bbb[1].id == "p3")
    assert(bbb_ccc.length == 1)
    assert(bbb_ccc[1].id == "p3")
    assert(example:getElementsByClassName('aaa,bbb').length == 0)
end
