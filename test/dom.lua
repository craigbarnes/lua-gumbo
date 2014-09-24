local gumbo = require "gumbo"

local input = [[
<div id=main class='foo bar baz etc'>
    <h1 id=heading>Title <!--comment --></h1>
</div>
]]

local document = assert(gumbo.parse(input))
local body = assert(document.documentElement[2])
local main = assert(document:getElementById("main"))
local heading = assert(document:getElementById("heading"))
local text = assert(heading.childNodes[1])
local comment = assert(heading.childNodes[2])

assert(document.nodeName == "#document")
assert(document.firstChild == body.parentNode)
assert(document.lastChild == body.parentNode)
assert(document.contentType == "text/html")
assert(document.characterSet == "UTF-8")
assert(document.URL == "about:blank")
assert(document.documentURI == document.URL)
assert(document.compatMode == "BackCompat")

assert(document:createElement("p").localName == "p")
assert(pcall(document.createElement, document, "Inv@lidName") == false)
assert(document:createTextNode("xyz..").data == "xyz..")
assert(document:createComment(" etc ").data == " etc ")

assert(body.nodeName == "BODY")
assert(body.nodeType == document.ELEMENT_NODE)
assert(body.localName == "body")
assert(body.parentNode.localName == "html")

assert(main == body[1])
assert(main.nodeName == "DIV")
assert(main.nodeName == main.tagName)
assert(main:hasAttribute("class") == true)
assert(main:getAttribute("class") == "foo bar baz etc")
assert(main.id == "main")
assert(main.id == main.attributes.id.value)
assert(main.className == "foo bar baz etc")
assert(main.className == main.attributes.class.value)

assert(text.nodeName == "#text")
assert(text.nodeType == document.TEXT_NODE)
assert(text.data == "Title ")
assert(text.parentNode == heading)
local textclone = assert(text:cloneNode())
assert(textclone.data == text.data)
assert(textclone.nodeName == "#text")
assert(textclone.parentNode == nil)

assert(comment.nodeName == "#comment")
assert(comment.nodeType == document.COMMENT_NODE)
assert(comment.data == "comment ")
assert(comment.parentNode == heading)
local commentclone = assert(comment:cloneNode())
assert(commentclone.data == comment.data)
assert(commentclone.nodeName == "#comment")
assert(commentclone.parentNode == nil)

assert(heading.attributes[1].value == "heading")
assert(heading.attributes.id.value == "heading")

assert(heading:hasChildNodes() == true)
assert(heading.childNodes.length == 2)
assert(heading.firstChild == heading.childNodes[1])
assert(heading.lastChild == heading.childNodes[2])

heading.childNodes[2]:remove()
assert(heading:hasChildNodes() == true)
assert(heading.childNodes.length == 1)
assert(heading.firstChild == heading.childNodes[1])
assert(heading.lastChild == heading.childNodes[1])

heading.childNodes[1]:remove()
assert(heading:hasChildNodes() == false)
assert(heading.childNodes.length == 0)
assert(heading.firstChild == nil)
assert(heading.lastChild == nil)
