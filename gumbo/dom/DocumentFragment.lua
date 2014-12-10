local util = require "gumbo.dom.util"
local merge = util.merge
local _ENV = nil

local DocumentFragment = merge("Node", "ParentNode", "NonElementParentNode", {
    type = "fragment",
    nodeName = "#document-fragment",
    nodeType = 11
})

return DocumentFragment
