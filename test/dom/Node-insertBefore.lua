local gumbo = require "gumbo"
local assert, pcall = assert, pcall
local _ENV = nil

local input = [[
<header id=header></header>
<div id="main" class="foo bar baz etc">
    <h1 id="h1">Title <!--comment --></h1>
</div>
<footer id=footer>...</footer>
]]

local document = assert(gumbo.parse(input))
local body = assert(document.body)
local main = assert(document:getElementById("main"))
local h1 = assert(document:getElementById("h1"))
local header = assert(document:getElementById("header"))
local footer = assert(document:getElementById("footer"))

assert(body.childElementCount == 3)
assert(body.children[1] == header)
assert(body.children[2] == main)
assert(body.children[3] == footer)

assert(body:insertBefore(main, header) == main)
assert(body.childElementCount == 3)
assert(body.children[1] == main)
assert(body.children[2] == header)
assert(body.children[3] == footer)

assert(body:insertBefore(header, header) == header)
assert(body.childElementCount == 3)
assert(body.children[1] == main)
assert(body.children[2] == header)
assert(body.children[3] == footer)

assert(body:insertBefore(h1, main) == h1)
assert(body.childElementCount == 4)
assert(body.firstElementChild == h1)

local p = assert(document:createElement("p"))
assert(p.parentNode == nil)
assert(body:insertBefore(p, h1) == p)
assert(p.parentNode == body)
assert(body.childElementCount == 5)
assert(body.firstElementChild == p)

assert(footer.childNodes.length == 1)
assert(main.parentNode == body)
assert(footer:insertBefore(main, footer.childNodes[1]) == main)
assert(main.parentNode == footer)
assert(body.childElementCount == 4)
assert(footer.childNodes.length == 2)
assert(footer.firstElementChild == main)
assert(body.children[3] == header)
assert(body.children[4] == footer)

local append = assert(document:createElement("a"))
assert(body:insertBefore(append) == append)
assert(body.childElementCount == 5)
assert(body.children[5] == append)

-- TODO: Add test coverage for every assertion in ensurePreInsertionValidity()
assert(not pcall(header.insertBefore, main, footer.childNodes[1]))
assert(not pcall(body.insertBefore, body, 9))
assert(not pcall(body.insertBefore, body, "string"))
assert(not pcall(body.insertBefore, body, true))
assert(not pcall(body.insertBefore, body, false))
assert(not pcall(body.insertBefore, body, nil))
assert(not pcall(body.insertBefore, body, body))
assert(not pcall(body.insertBefore, body, document))
assert(not pcall(main.insertBefore, main, body))
