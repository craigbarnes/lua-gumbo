local gumbo = require "gumbo"

local document = assert(gumbo.parse("\t\t<!--one--><!--two--><h1>Hi</h1>", 16))
assert(document.root and document.root == document[3])
assert(document[1].text == "one")
assert(document[2].text == "two")
assert(document[1].line == 1)
assert(document[1].column == 32)
assert(document[1].offset == 2)

document = assert(gumbo.parse(string.rep("<div>", 500)), "stack check failed")
assert(document.root[2][1][1][1][1][1][1][1][1][1][1][1].tag == "div")

assert(not gumbo.parse_file(0), "Passing invalid argument type should fail")
assert(not gumbo.parse_file".", "Passing a directory name should fail")
assert(not gumbo.parse_file"_", "Passing a non-existant filename should fail")
