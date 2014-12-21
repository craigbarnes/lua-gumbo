local parse = require("gumbo").parse
local assert = assert
local _ENV = nil

assert(parse("<title>  test   x   y  </title>").title == "test x y")
assert(parse("<title>Hello  world!</title>").title == "Hello world!")
assert(parse("<title> foo \t\rb\n\far\r\n</title>").title == "foo b ar")
assert(parse("<title></title>").title == "")
assert(parse("<title> </title>").title == "")
assert(parse("<title> \n\t    \f  \r </title>").title == "")
assert(parse("").title == "")
