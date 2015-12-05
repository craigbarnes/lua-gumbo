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

do
    local document = assert(parse("<title>Initial Title</title>"))
    assert(document.title == "Initial Title")
    local newTitle = "\t  \r\n\r\n Setter Test \n\n"
    document.title = newTitle
    assert(document.titleElement.childNodes[1].data == newTitle)
    assert(document.title == "Setter Test")
end

do
    local document = assert(parse("<p>This document has no title</p>"))
    assert(document.title == "")
    document.title = "New Title"
    assert(document.titleElement.childNodes[1].data == "New Title")
    assert(document.title == "New Title")
    document.head:remove()
    document.title = "Test"
    assert(document.title == "")
end
