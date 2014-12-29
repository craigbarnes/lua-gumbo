local Set = require "gumbo.Set"
local assert, rawequal = assert, rawequal
local _ENV = nil
local base = Set{"div", "table", "h1"}

do
    local union1 = assert(base + Set{"a", "p"})
    local union2 = assert(base + Set{"p", "a"})
    assert(union1 == union2)
    assert(not rawequal(union1, union2))
end

do
    local u1 = assert(base + Set{"a", "p"})
    local u2 = assert(base + Set{"a"})
    local u3 = assert(base + Set{"p"})
    assert(u1 ~= u2)
    assert(u1 ~= u3)
    assert(u2 ~= u3)
    assert(not rawequal(u1, u2))
    assert(not rawequal(u1, u3))
    assert(not rawequal(u2, u3))

    assert(u2:isSubsetOf(u1) == true)
    assert(u3:isSubsetOf(u1) == true)
    assert(u1:isSubsetOf(u2) == false)
    assert(u1:isSubsetOf(u3) == false)
    assert(u2 < u1 == true)
    assert(u3 < u1 == true)
    assert(u1 < u2 == false)
    assert(u1 < u3 == false)
end

do
    assert(base + Set{"a"} == base:union(Set{"a"}))
    assert(base + Set{"a"} ~= base:union(Set{"p"}))
end
