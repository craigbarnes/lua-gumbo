local util = require "gumbo.dom.util"
local Node = require "gumbo.dom.Node"
local ChildNode = require "gumbo.dom.ChildNode"
local rawget, setmetatable = rawget, setmetatable
local _ENV = nil

local DocumentType = util.merge(Node, ChildNode, {
    type = "doctype",
    nodeType = 10,
    publicId = "",
    systemId = ""
})

function DocumentType:cloneNode()
    local clone = {
        name = rawget(self, "name"),
        publicId = rawget(self, "publicId"),
        systemId = rawget(self, "systemId")
    }
    return setmetatable(clone, DocumentType)
end

function DocumentType.getters:nodeName()
    return self.name
end

return DocumentType
