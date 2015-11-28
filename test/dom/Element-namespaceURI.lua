local gumbo = require "gumbo"
local assert = assert
local _ENV = nil

local input = [[
    <!DOCTYPE html>
    <html xmlns="http://www.w3.org/1999/xhtml">
    <head><title>NamespaceURI Test</title></head>
    <body>
        <math xmlns="http://www.w3.org/1998/Math/MathML"></math>
        <svg xmlns="http://www.w3.org/2000/svg"></svg>
        <math></math>
        <svg></svg>
    </body>
    </html>
]]

local document = assert(gumbo.parse(input))
local mathmls = assert(document.body:getElementsByTagName("math"))
local svgs = assert(document.body:getElementsByTagName("svg"))

assert(mathmls.length == 2)
assert(svgs.length == 2)
assert(mathmls[1].namespaceURI == "http://www.w3.org/1998/Math/MathML")
assert(mathmls[2].namespaceURI == "http://www.w3.org/1998/Math/MathML")
assert(svgs[1].namespaceURI == "http://www.w3.org/2000/svg")
assert(svgs[2].namespaceURI == "http://www.w3.org/2000/svg")
assert(document.documentElement.namespaceURI == "http://www.w3.org/1999/xhtml")
assert(document.body.namespaceURI == "http://www.w3.org/1999/xhtml")
assert(document.head.namespaceURI == "http://www.w3.org/1999/xhtml")
