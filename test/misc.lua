local gumbo = require "gumbo"
local parse, parse_file = gumbo.parse, gumbo.parse_file
local assert, type, open, rep = assert, type, io.open, string.rep
local load = loadstring or load
local _ENV = nil

do
    local input = "\t\t<!--one--><!--two--><h1>Hi</h1>"
    local document = assert(parse(input, 16))
    local html = assert(document.documentElement)

    -- Check that document structure is as expected
    assert(document.childNodes.length == 3)
    assert(#document.childNodes == 3)
    assert(html == document[3])
    assert(document[1].data == "one")
    assert(document[2].data == "two")
    assert(html.innerHTML == "<head></head><body><h1>Hi</h1></body>")

    -- Check that tab_stop parameter is used
    assert(document[1].line == 1)
    assert(document[1].column == 32)
    assert(document[1].offset == 2)

    -- Check that adding new fields isn't prevented by __newindex metamethods
    assert(document.nonExistantField == nil)
    document.nonExistantField = "new-value"
    assert(document.nonExistantField == "new-value")
    assert(html.nonExistantField == nil)
    html.nonExistantField = "new-value"
    assert(html.nonExistantField == "new-value")
end

do -- Check that Attr.escapedValue works correctly
    local doc = assert(parse[[<div id=test class='x&nbsp;"&amp"&amp;;"'>]])
    local test = assert(doc:getElementById("test"))
    local class = test.attributes.class
    assert(class.value == [[x "&"&;"]])
    assert(class.escapedValue == [[x&nbsp;&quot;&amp;&quot;&amp;;&quot;]])
end

do -- Check that Text.escapedData works correctly
    local doc = assert(parse[[<p id=elem>x &foo bar><< &nbsp;</p>]])
    local elem = assert(doc:getElementById("elem"))
    local text = assert(elem.childNodes[1])
    assert(text.data == [[x &foo bar><<  ]])
    assert(text.escapedData == [[x&nbsp;&amp;foo bar&gt;&lt;&lt; &nbsp;]])
end

do -- Make sure deeply nested elements don't cause a stack overflow
    local input = rep("<div>", 500)
    local document = assert(parse(input), "stack check failed")
    assert(document.body[1][1][1][1][1][1][1][1][1][1][1].localName == "div")
end

do -- Check that parse_file works the same with a filename as with a file
    local a = assert(parse_file(open("test/data/t1.html")))
    local b = assert(parse_file("test/data/t1.html"))
    assert(a.documentElement.innerHTML == b.documentElement.innerHTML)
end

-- Check that file open/read errors are handled
assert(not parse_file(0), "Passing invalid argument type should fail")
assert(not parse_file".", "Passing a directory name should fail")
assert(not parse_file"_", "Passing a non-existant filename should fail")
