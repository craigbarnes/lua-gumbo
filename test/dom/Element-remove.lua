-- https://github.com/w3c/web-platform-tests/blob/8c07290db5014705e7daa45e3690a54018d27bd5/dom/nodes/Element-remove.html

local gumbo = require "gumbo"

local input = [[
<!DOCTYPE html>
<meta charset=utf-8>
<title>Element.remove</title>
<link rel=help href="http://dom.spec.whatwg.org/#dom-childnode-remove">
<div id=log></div>
]]

local document = assert(gumbo.parse(input))

-- https://github.com/w3c/web-platform-tests/blob/8c07290db5014705e7daa45e3690a54018d27bd5/dom/nodes/ChildNode-remove.js
local function testRemove(node, parent)
    -- Element should support remove()
    assert(node.remove)
    assert(type(node.remove) == "function")

    -- remove() should work if element doesn't have a parent
    assert(node.parentNode == nil, "Node should not have a parent")
    assert(node:remove() == nil)
    assert(node.parentNode == nil, "Removed new node should not have a parent")

    -- remove() should work if element does have a parent
    assert(node.parentNode == nil, "Node should not have a parent")
    parent:appendChild(node)
    assert(node.parentNode == parent, "Appended node should have a parent")
    assert(node:remove() == nil)
    assert(node.parentNode == nil, "Removed node should not have a parent")
    assert(parent.childNodes.length == 0, "Parent should not have children")

    -- remove() should work if element does have a parent and siblings
    assert(node.parentNode == nil, "Node should not have a parent")
    local before = parent:appendChild(document:createComment("before"))
    parent:appendChild(node)
    local after = parent:appendChild(document:createComment("after"))
    assert(node.parentNode == parent, "Appended node should have a parent")
    assert(node:remove() == nil)
    assert(node.parentNode == nil, "Removed node should not have a parent")
    assert(parent.childNodes.length == 2, "Parent should have two children left")
    assert(parent.childNodes[1] == before)
    assert(parent.childNodes[2] == after)
end

local node = assert(document:createElement("div"))
local parentNode = assert(document:createElement("div"))
testRemove(node, parentNode, "element")
