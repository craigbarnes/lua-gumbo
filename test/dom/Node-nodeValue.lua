local gumbo = require "gumbo"
local assert = assert
local _ENV = nil

local input = [[
<!doctype html>
<meta charset=utf-8>
<title>Node.nodeValue</title>
<link rel=help href="https://dom.spec.whatwg.org/#dom-node-nodevalue">
<div id=log></div>
]]

local document = assert(gumbo.parse(input))

do -- Text.nodeValue
    local the_text = document:createTextNode("A span!")
    assert(the_text.nodeValue == "A span!")
    assert(the_text.data == "A span!")
    the_text.nodeValue = "test again"
    assert(the_text.nodeValue == "test again")
    assert(the_text.data == "test again")
    the_text.nodeValue = nil
    assert(the_text.nodeValue == "")
    assert(the_text.data == "")
end

do -- Comment.nodeValue
    local the_comment = document:createComment("A comment!")
    assert(the_comment.nodeValue == "A comment!")
    assert(the_comment.data == "A comment!")
    the_comment.nodeValue = "test again"
    assert(the_comment.nodeValue == "test again")
    assert(the_comment.data == "test again")
    the_comment.nodeValue = nil
    assert(the_comment.nodeValue == "")
    assert(the_comment.data == "")
end

do -- Element.nodeValue
    local the_link = document:createElement("a")
    assert(the_link.nodeValue == nil)
    the_link.nodeValue = "foo"
    assert(the_link.nodeValue == nil)
end

do -- Document.nodeValue
    assert(document.nodeValue == nil)
    document.nodeValue = "foo"
    assert(document.nodeValue == nil)
end

do -- DocumentType.nodeValue
    local the_doctype = document.doctype
    assert(the_doctype.nodeValue == nil)
    the_doctype.nodeValue = "foo"
    assert(the_doctype.nodeValue == nil)
end

--[[ TODO:
do -- DocumentFragment.nodeValue
    local the_frag = document:createDocumentFragment()
    assert(the_frag.nodeValue == nil)
    the_frag.nodeValue = "foo"
    assert(the_frag.nodeValue == nil)
end
]]
