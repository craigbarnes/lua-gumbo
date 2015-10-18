local gumbo = require "gumbo"
local sanitize = require "gumbo/sanitize"
local assert = assert
local _ENV = nil

-- TODO: Add test for href scheme with leading NULL byte

local input = [[
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>HTML5 Sanitizer Test Input</title>
</head>
<body>
    <a href=foo>#1</a>
    <a href=bar>#2</a>
    <a href=etc>#3</a>
    <a href='http:127.0.0.1'>#4</a>
    <a href='http://127.0.0.1'>#5</a>
    <a href='  http://127.0.0.1'>#6</a>
    <a href='&#10;&#10;&#9;http:127.0.0.1'>#7</a>
    <a href='  javascript: alert("oops!")' data-unsafe="yes">#8</a>
    <a href='  foo--bar : alert()'>#9</a>
    <a href='  non-whitelisted-scheme: alert()' data-unsafe="yes">#10</a>
    <a href='  javascript  : alert()'>#11</a>
    <a href='&#10;&#9;javascript: alert("oops!")' data-unsafe="yes">#12</a>
</body>
</html>
]]

local document = assert(gumbo.parse(input))
sanitize(document.body)

for node in document.body:walk() do
    if node.type == "element" then
        assert(node.localName == "a")
        assert(node:hasAttribute("href") ~= node:hasAttribute("data-unsafe"))
    end
end
