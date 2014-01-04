-- This file contains tests for various aspects of lua-gumbo that
-- aren't covered by the serialization or html5lib tests

local gumbo = require "gumbo"
local document = assert(gumbo.parse("\t\t<!--one--><!--two--><h1>Hi</h1>", 16))

-- Check that document.root is set correctly
assert(#document == 3)
assert(document.root and document.root == document[3])
assert(document[1].text == "one")
assert(document[2].text == "two")

-- Check that tab_stop parameter is used
assert(document[1].line == 1)
assert(document[1].column == 32)
assert(document[1].offset == 2)

-- Make sure deeply nested elements don't cause a stack overflow
document = assert(gumbo.parse(string.rep("<div>", 500)), "stack check failed")
assert(document.root[2][1][1][1][1][1][1][1][1][1][1][1].tag == "div")

-- Check that file open/read errors are handled
assert(not gumbo.parse_file(0), "Passing invalid argument type should fail")
assert(not gumbo.parse_file".", "Passing a directory name should fail")
assert(not gumbo.parse_file"_", "Passing a non-existant filename should fail")
