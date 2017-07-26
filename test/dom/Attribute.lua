local gumbo = require "gumbo"
local assert = assert
local _ENV = nil

local function assertAttr(attr, value, name, localName, prefix, namespace)
    assert(attr.value == value)
    assert(attr.name == name)
    assert(attr.localName == localName)
    assert(attr.prefix == prefix)
    assert(attr.namespaceURI == namespace)
end

local document = assert(gumbo.parse([[
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" lang="en" xml:lang="en">
<head>
    <meta charset="utf-8"/>
    <title>Attribute Tests</title>
</head>
<body>
    <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
        <rect x="10" y="10" height="100" width="100" style="fill: blue"/>
    </svg>
</body>
</html>
]]))

local root = assert(document.documentElement)
assertAttr(root.attributes[3], "en", "xml:lang", "xml:lang", nil, nil)

local svg = assert(document:getElementsByTagName("svg")[1])
local XMLNS = "http://www.w3.org/2000/xmlns/"
assertAttr(svg.attributes[1], "http://www.w3.org/2000/svg", "xmlns", "xmlns", "xmlns", XMLNS)
assertAttr(svg.attributes[2], "http://www.w3.org/1999/xlink", "xlink", "xlink", "xmlns", XMLNS)

-- TODO: Add tests from github.com/w3c/web-platform-tests/blob/master/dom/nodes/attributes.html
