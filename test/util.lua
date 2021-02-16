local util = require "gumbo.util"
local createtable = assert(util.createtable)
local trimAndCollapse = assert(util.trimAndCollapseWhitespace)

assert(type(createtable(0, 0)) == "table")
assert(type(createtable(128, 32)) == "table")
assert(not pcall(createtable, 0, -1))
assert(not pcall(createtable, -1, 0))

assert(trimAndCollapse(" ") == "")
assert(trimAndCollapse("") == "")
assert(trimAndCollapse("\r\t \n") == "")
assert(trimAndCollapse("x") == "x")
assert(trimAndCollapse("x  \t\t\t\t  y") == "x y")
assert(trimAndCollapse("\n  x  y  z  \r\n") == "x y z")
assert(trimAndCollapse("\t\n   \0   \0   . \r\t\f\n") == "\0 \0 .")
assert(trimAndCollapse(" \t\n foo\n\r\t  bar  baz \t\r") == "foo bar baz")
