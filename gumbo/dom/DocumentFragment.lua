local util = require "gumbo.dom.util"
local Node = require "gumbo.dom.Node"
local ParentNode = require "gumbo.dom.ParentNode"
local Document = require "gumbo.dom.Document"
local assert = assert
local _ENV = nil

local DocumentFragment = util.merge(Node, ParentNode, {
    type = "fragment",
    nodeName = "#document-fragment",
    nodeType = 11,
    getElementById = assert(Document.getElementById)
})

return DocumentFragment
