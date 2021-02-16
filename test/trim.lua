local util = require "gumbo.util"
local trim = assert(util.trim)

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
