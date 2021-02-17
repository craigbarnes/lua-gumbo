local util = require "gumbo.util"
local trim = assert(util.trim)
local trimAndCollapse = assert(util.trimAndCollapseWhitespace)
local createtable = assert(util.createtable)

local function gsub_trim(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

assert(trim("  ") == "")
assert(trim("") == "")
assert(trim("\t\r\nz") == "z")

do
    local s = " \t \r\n\f   foo bar\n \t\r \n\n  "
    assert(trim(s) == "foo bar")
    assert(trim(s) == gsub_trim(s))
end

do
    local s = "\t \0 \0 \0  "
    assert(trim(s) == "\0 \0 \0")
    assert(trim(s) == gsub_trim(s))
end

assert(trimAndCollapse(" ") == "")
assert(trimAndCollapse("") == "")
assert(trimAndCollapse("\r\t \n") == "")
assert(trimAndCollapse("x") == "x")
assert(trimAndCollapse("x  \t\t\t\t  y") == "x y")
assert(trimAndCollapse("\n  x  y  z  \r\n") == "x y z")
assert(trimAndCollapse("\t\n   \0   \0   . \r\t\f\n") == "\0 \0 .")
assert(trimAndCollapse(" \t\n foo\n\r\t  bar  baz \t\r") == "foo bar baz")

assert(type(createtable(0, 0)) == "table")
assert(type(createtable(128, 32)) == "table")
assert(not pcall(createtable, 0, -1))
assert(not pcall(createtable, -1, 0))
