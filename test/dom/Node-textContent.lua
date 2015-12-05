local gumbo = require "gumbo"

local document = assert(gumbo.parse [[
<p>Some text</p>
<section id="section"><div><p id="inner">
More text
</p></div></section><!--Comment #1-->
]])

local inner = assert(document:getElementById("inner"))
local section = assert(document:getElementById("section"))
local comment = assert(section.nextSibling)
assert(inner.localName == "p")
assert(comment.type == "comment")
assert(inner.textContent == "\nMore text\n")
assert(comment.textContent == "Comment #1")
assert(document.body.textContent == "Some text\n\nMore text\n\n")
