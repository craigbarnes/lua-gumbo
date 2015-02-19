local gumbo = require "gumbo"
local assert = assert
local _ENV = nil

do
    local input = '<div id="main"><h1 id="heading">Title</h1></div>'
    local document = assert(gumbo.parse(input))
    local main = assert(document:getElementById("main"))
    local heading = assert(document:getElementById("heading"))
    assert(document:getElementsByTagName("head")[1] == document.head)
    assert(document:getElementsByTagName("body")[1] == document.body)
    assert(document:getElementsByTagName("div")[1] == main)
    assert(document:getElementsByTagName("*").length == 5)
    assert(document:getElementsByTagName("").length == 0)
    assert(document.body:getElementsByTagName("h1")[1] == heading)
end

do
    local tendivs = assert(("<div>"):rep(10))
    local document = assert(gumbo.parse(tendivs))
    assert(document:getElementsByTagName("div").length == 10)
    assert(document.body.childNodes[1]:getElementsByTagName("div").length == 9)
end
