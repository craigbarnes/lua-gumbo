local util = require "gumbo.util"
local createtable = assert(util.createtable)

assert(type(createtable(0, 0)) == "table")
assert(type(createtable(128, 32)) == "table")
assert(not pcall(createtable, 0, -1))
assert(not pcall(createtable, -1, 0))
