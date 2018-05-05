local gumbo = require "gumbo"
local parse = gumbo.parse
local assert = assert
local tree_depth_limit = 512
local _ENV = nil

do -- Make sure the stack doesn't overflow before the depth limit is reached
    local n = tree_depth_limit - 2
    local input = ("<div>"):rep(n)
    local document = assert(parse(input), "stack check failed")
    assert(document.body.childNodes[1].childNodes[1].localName == "div")
    assert(document.body.innerHTML == input .. ("</div>"):rep(n))
end

do -- Make sure the depth limit is enforced
    local n = tree_depth_limit - 1
    local input = ("<div>"):rep(n)
    local document, errmsg = parse(input)
    assert(document == nil)
    assert(errmsg ~= nil)
    assert(errmsg:find("depth limit"))
end
