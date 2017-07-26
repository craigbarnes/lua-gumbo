local gumbo = require "gumbo"
local parse = gumbo.parse
local assert = assert
local _ENV = nil

do -- Make sure deeply nested elements don't cause a stack overflow
    local n = 390
    local input = ("<div>"):rep(n)
    local document = assert(parse(input), "stack check failed")
    assert(document.body.childNodes[1].childNodes[1].localName == "div")
    assert(document.body.innerHTML == input .. ("</div>"):rep(n))
end

do -- Make sure maximum tree depth limit is enforced
    local input = ("<div>"):rep(401)
    local document, errmsg = parse(input)
    assert(document == nil)
    assert(errmsg ~= nil)
    assert(errmsg:find("depth limit"))
end
