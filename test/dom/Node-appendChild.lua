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

assert(body:appendChild(main) == main)
assert(body.childElementCount == 3)
assert(body.children[1] == header)
assert(body.children[2] == footer)
assert(body.children[3] == main)

assert(body:appendChild(header) == header)
assert(body.childElementCount == 3)
assert(body.children[1] == footer)
assert(body.children[2] == main)
assert(body.children[3] == header)

assert(body:appendChild(h1) == h1)
assert(body.childElementCount == 4)
assert(body.lastElementChild == h1)

local p = assert(document:createElement("p"))
assert(p.parentNode == nil)
assert(body:appendChild(p) == p)
assert(p.parentNode == body)
assert(body.childElementCount == 5)
assert(body.lastElementChild == p)

assert(header.childNodes.length == 0)
assert(main.parentNode == body)
assert(header:appendChild(main) == main)
assert(main.parentNode == header)
assert(body.childElementCount == 4)
assert(header.childNodes.length == 1)
assert(header.firstElementChild == main)
assert(body.children[2] == header)

-- TODO: Add test coverage for every assertion in ensurePreInsertionValidity()
assert(not pcall(body.appendChild, body, 9))
assert(not pcall(body.appendChild, body, "string"))
assert(not pcall(body.appendChild, body, true))
assert(not pcall(body.appendChild, body, false))
assert(not pcall(body.appendChild, body, nil))
assert(not pcall(body.appendChild, body, body))
assert(not pcall(body.appendChild, body, document))
assert(not pcall(main.appendChild, main, body))
