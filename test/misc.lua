local gumbo = require "gumbo"
local parse, parseFile = gumbo.parse, gumbo.parseFile
local assert, open, pcall = assert, io.open, pcall
local _ENV = nil

do
    local input = "\t\t<!--one--><!--two--><h1>Hi</h1>"
    local document = assert(parse(input, 16))
    local html = assert(document.documentElement)

    -- Check that document structure is as expected
    assert(document.childNodes.length == 3)
    assert(#document.childNodes == 3)
    assert(html == document.childNodes[3])
    assert(document.childNodes[1].data == "one")
    assert(document.childNodes[2].data == "two")
    assert(html.innerHTML == "<head></head><body><h1>Hi</h1></body>")

    -- Check that tab_stop parameter is used
    assert(document.childNodes[1].line == 1)
    assert(document.childNodes[1].column == 32)
    assert(document.childNodes[1].offset == 2)

    -- Check that adding new fields isn't prevented by __newindex metamethods
    assert(document.nonExistantField == nil)
    document.nonExistantField = "new-value"
    assert(document.nonExistantField == "new-value")
    assert(html.nonExistantField == nil)
    html.nonExistantField = "new-value"
    assert(html.nonExistantField == "new-value")
end

do -- Check that Attribute.escapedValue works correctly
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
    local n = 500
    local input = ("<div>"):rep(n)
    local document = assert(parse(input), "stack check failed")
    assert(document.body.childNodes[1].childNodes[1].localName == "div")
    assert(document.body.innerHTML == input .. ("</div>"):rep(n))
end

do -- Make sure maximum tree depth limit is enforced
    local input = ("<div>"):rep(801)
    local document, errmsg = parse(input)
    assert(document == nil)
    assert(errmsg ~= nil)
    assert(errmsg:find("depth limit"))
end

do -- Check that parseFile works the same with a filename as with a file
    local a = assert(parseFile(open("test/data/t1.html")))
    local b = assert(parseFile("test/data/t1.html"))
    assert(a.documentElement.innerHTML == b.documentElement.innerHTML)
end

do -- Check that childNodes field is the same table after appendChild()
    local document = assert(parse(""))
    local body = assert(document.body)
    local childNodes = assert(body.childNodes)
    assert(childNodes.length == 0)
    local div = assert(document:createElement("div"))
    assert(body:appendChild(div))
    assert(body.childNodes.length == 1)
    assert(childNodes.length == 1)
    assert(body.childNodes == childNodes)
end

do -- Check that writing to default, shared childNodes table throws an error
    local document = assert(parse("..."))
    local body = assert(document.body)
    local text = assert(body.childNodes[1])
    assert(text.childNodes.length == 0)
    local div = assert(document:createElement("div"))
    assert(not pcall(function() text.childNodes[1] = div end))
    assert(not pcall(text.appendChild, text, div))
end

do -- Check that passing invalid arguments throws an error
    assert(not pcall(parseFile, 0))
    assert(not pcall(parseFile, nil))
    assert(not pcall(parseFile, true))
    assert(not pcall(parseFile, {}))
    assert(not pcall(parseFile, parseFile))
    local file = open("test/data/t1.html")
    assert(pcall(parseFile, file, 8, "iframe", "html"))
    assert(pcall(parseFile, file, 8, "path", "svg"))
    assert(pcall(parseFile, file, 8, "table", nil))
    assert(pcall(parseFile, file, 8, nil, nil))
    assert(not pcall(parseFile, file, true))
    assert(not pcall(parseFile, file, {}))
    assert(not pcall(parseFile, file, 8, "div", "badns"))
    assert(not pcall(parseFile, file, nil, "div", "badns"))
    assert(not pcall(parseFile, file, "div", "badns"))
    assert(not pcall(parseFile, file, "div", true))
    assert(not pcall(parseFile, file, "div"))
    assert(not pcall(parseFile, file, "div", "html", 8))
    assert(not pcall(parseFile, file, nil, nil, 8))
end

-- Check that file open/read errors are handled
assert(not parseFile".", "Passing a directory name should return nil")
assert(not parseFile"_", "Passing a non-existant filename should return nil")

-- Check that parse_file alias is present (for API backwards compatibility)
assert(gumbo.parse_file == gumbo.parseFile)
