-- This file contains tests for various aspects of lua-gumbo that
-- aren't covered by the serialization or html5lib tests

local gumbo = require "gumbo"
local document = assert(gumbo.parse("\t\t<!--one--><!--two--><h1>Hi</h1>", 16))

-- Check that document.documentElement is set correctly
assert(document.childNodes.length == 3)
assert(#document.childNodes == 3)
assert(document.documentElement and document.documentElement == document[3])
assert(document[1].data == "one")
assert(document[2].data == "two")

-- Check that tab_stop parameter is used
assert(document[1].line == 1)
assert(document[1].column == 32)
assert(document[1].offset == 2)

-- Make sure deeply nested elements don't cause a stack overflow
document = assert(gumbo.parse(string.rep("<div>", 500)), "stack check failed")
assert(document.documentElement[2][1][1][1][1][1][1][1][1].localName == "div")

-- Check that parse_file works the same with a filename as with a file handle
local to_table = require "gumbo.serialize.table"
local a = assert(gumbo.parse_file(io.open("test/t1.html"), 4))
local b = assert(gumbo.parse_file("test/t1.html", 4))
assert(to_table(a) == to_table(b))

-- Ensure that serialized table syntax is valid
local fn = assert((loadstring or load)('return ' .. to_table(a)))
local t = assert(fn())
assert(type(t) == "table")

-- Check that file open/read errors are handled
assert(not gumbo.parse_file(0), "Passing invalid argument type should fail")
assert(not gumbo.parse_file".", "Passing a directory name should fail")
assert(not gumbo.parse_file"_", "Passing a non-existant filename should fail")
