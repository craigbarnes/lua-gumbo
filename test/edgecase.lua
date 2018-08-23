local gumbo = require "gumbo"
local parse = gumbo.parse
local assert = assert
local _ENV = nil

do
    local input = "<body><WhatAcrazyNAME></WhatAcrazyNAME>"
    local document = assert(parse(input))
    local body = assert(document.body)
    assert(body.childNodes.length == 1)
    local node = assert(body.childNodes[1])
    assert(node.type == "element")
    assert(node.localName == "whatacrazyname")
end

do
    local input = "<body><SVG><FOREIGNOBJECT></FOREIGNOBJECT></SVG>"
    local document = assert(parse(input))
    local body = assert(document.body)
    assert(body.childNodes.length == 1)

    local svg = assert(body.childNodes[1])
    assert(svg.type == "element")
    assert(svg.localName == "svg")

    local node = assert(svg.childNodes[1])
    assert(node.type == "element")
    assert(node.localName == "foreignObject")
end

do
    local input = "<body><MATH><FOREIGNOBJECT></FOREIGNOBJECT></math>"
    local document = assert(parse(input))
    local body = assert(document.body)
    assert(body.childNodes.length == 1)

    local math = assert(body.childNodes[1])
    assert(math.type == "element")
    assert(math.localName == "math")

    local node = assert(math.childNodes[1])
    assert(node.type == "element")
    assert(node.localName == "foreignobject")
end
