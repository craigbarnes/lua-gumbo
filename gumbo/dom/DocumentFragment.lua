local util = require "gumbo.dom.util"
local Node = require "gumbo.dom.Node"
local ParentNode = require "gumbo.dom.ParentNode"
local NonElementParentNode = require "gumbo.dom.NonElementParentNode"
local _ENV = nil

local DocumentFragment = util.merge(Node, ParentNode, NonElementParentNode, {
    type = "fragment",
    nodeName = "#document-fragment",
    nodeType = 11
})

return DocumentFragment
