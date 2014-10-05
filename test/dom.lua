local gumbo = require "gumbo"

local input = [[
<div id="main" class="foo bar baz etc">
    <h1 id="heading">Title <!--comment --></h1>
</div>
]]

local document = assert(gumbo.parse(input))
local html = assert(document.documentElement)
local head = assert(document.head)
local body = assert(document.body)
local main = assert(document:getElementById("main"))
local heading = assert(document:getElementById("heading"))
local text = assert(heading.childNodes[1])
local comment = assert(heading.childNodes[2])

assert(document:getElementsByTagName("head")[1] == head)
assert(document:getElementsByTagName("body")[1] == body)
assert(document:getElementsByTagName("div")[1] == main)
assert(body:getElementsByTagName("h1")[1] == heading)
local tendivs = assert(gumbo.parse(string.rep("<div>", 10)))
assert(tendivs:getElementsByTagName("div").length == 10)

assert(document.nodeName == "#document")
assert(document.firstChild == body.parentNode)
assert(document.lastChild == body.parentNode)
assert(document.contentType == "text/html")
assert(document.characterSet == "UTF-8")
assert(document.URL == "about:blank")
assert(document.documentURI == document.URL)
assert(document.compatMode == "BackCompat")
document.nodeName = "this-is-readonly"
assert(document.nodeName == "#document")

assert(document:createElement("p").localName == "p")
assert(pcall(document.createElement, document, "Inv@lidName") == false)
assert(document:createTextNode("xyz..").data == "xyz..")
assert(document:createComment(" etc ").data == " etc ")

assert(html.localName == "html")
assert(html.nodeType == document.ELEMENT_NODE)
assert(html.parentNode == document)
assert(html.innerHTML == "<head></head><body>"..input.."</body>")
assert(html.outerHTML == "<html><head></head><body>"..input.."</body></html>")

assert(head.childNodes.length == 0)
assert(head.innerHTML == "")
assert(head.outerHTML == "<head></head>")

assert(body == html.childNodes[2])
assert(body.nodeName == "BODY")
assert(body.nodeType == document.ELEMENT_NODE)
assert(body.localName == "body")
assert(body.parentNode.localName == "html")
assert(body.innerHTML == input)
assert(body.outerHTML == "<body>" .. input .. "</body>")

assert(main == body[1])
assert(main:getElementsByTagName("div").length == 0)
assert(main.nodeName == "DIV")
assert(main.nodeName == main.tagName)
assert(main:hasAttribute("class") == true)
assert(main:getAttribute("class") == "foo bar baz etc")
assert(main.id == "main")
assert(main.id == main.attributes.id.value)
assert(main.className == "foo bar baz etc")
assert(main.className == main.attributes.class.value)
assert(main.classList[1] == "foo")
assert(main.classList[2] == "bar")
assert(main.classList[3] == "baz")
assert(main.classList[4] == "etc")
assert(main.classList.length == 4)
assert(main:hasChildNodes() == true)
local mainclone = assert(main:cloneNode())
assert(mainclone.nodeName == "DIV")
assert(mainclone:getAttribute("class") == "foo bar baz etc")
assert(mainclone.attributes.id.value == "main")
assert(mainclone.attributes[1].value == "main")
assert(main.classList.length == 4)
assert(mainclone:hasChildNodes() == false)

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
heading.id = "new-id"
assert(heading.attributes[1].value == "new-id")
assert(heading.attributes.id.value == "new-id")

heading.className = "x y z"
assert(heading.className == "x y z")
assert(heading.attributes[2].value == "x y z")
assert(heading.attributes.class.value == "x y z")

assert(heading:hasChildNodes() == true)
assert(heading.childNodes.length == 2)
assert(heading.children.length == 0)
assert(heading.firstChild == heading.childNodes[1])
assert(heading.lastChild == heading.childNodes[2])

heading.firstChild = false
heading.lastChild = "bla"
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
