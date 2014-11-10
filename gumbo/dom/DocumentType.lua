local util = require "gumbo.dom.util"
local rawget, setmetatable = rawget, setmetatable
local _ENV = nil

local DocumentType = util.merge("Node", "ChildNode", {
    type = "doctype",
    nodeType = 10,
    publicId = "",
    systemId = ""
})

DocumentType.__index = util.indexFactory(DocumentType)

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
