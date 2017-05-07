local selector = require "gumbo.selector"
local parse = assert(selector.parse)

local function assertSelector(selector)
    local n = #selector
    local r = parse(selector)
    if r == nil or r < n then
        error("Invalid selector", 2)
    end
end

local _ENV = nil

assertSelector("h1")
assertSelector(" h1, h2, h3 ")
assertSelector(" /* comment * /  */  h1, h2, h3 ")
assertSelector("h1#id.class")
assertSelector("h1 > div > code[id ^= quim]")
assertSelector("div p *[href]")
assertSelector("div ol>li p")
assertSelector("h1.opener + h2")
assertSelector("main > h1:first-child")

assertSelector('[foo="bar"] /* sanity check */')
assertSelector('[foo="bar" i]')
assertSelector('[foo="bar" /**/ i]')
assertSelector('[foo="bar"/**/i]')

assertSelector("[foo='BAR'] /* sanity check (valid) */")
assertSelector("[foo='bar' i]")
assertSelector("[foo='bar' I]")
assertSelector("[foo=bar i]")
assertSelector('[foo="bar" i]')
assertSelector("[foo='bar'i]")
assertSelector("[foo='bar'i ]")
assertSelector("[foo='bar' i ]")
assertSelector("[foo='bar' /**/ i]")
assertSelector("[foo='bar' i /**/ ]")
assertSelector("[foo='bar'/**/i/**/]")
assertSelector("[foo=bar/**/i]")
assertSelector("[foo='bar'\ti\t] /* \\t */")
assertSelector("[foo='bar'\ni\n] /* \\n */")
assertSelector("[foo='bar'\ri\r] /* \\r */")
assertSelector("[foo='bar' \\i]")
assertSelector("[foo='bar' \\69]")
assertSelector("[foo~='bar' i]")
assertSelector("[foo^='bar' i]")
assertSelector("[foo$='bar' i]")
assertSelector("[foo*='bar' i]")
assertSelector("[foo|='bar' i]")
assertSelector("[|foo='bar' i]")
assertSelector("[*|foo='bar' i]")
