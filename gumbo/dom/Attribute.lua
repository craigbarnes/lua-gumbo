local util = require "gumbo.dom.util"
local assert = assert
local _ENV = nil

local Attribute = {getters = {}}
Attribute.__index = assert(util.indexFactory(Attribute))

local namespaces = {
    xlink = "http://www.w3.org/1999/xlink",
    xml = "http://www.w3.org/XML/1998/namespace",
    xmlns = "http://www.w3.org/2000/xmlns/"
}

local escmap = {
    ["\194\160"] = "&nbsp;",
    ["&"] = "&amp;",
    ['"'] = "&quot;"
}

function Attribute.getters:localName()
    return self.name
end

function Attribute.getters:namespaceURI()
    local prefix = self.prefix
    if prefix then
        return namespaces[prefix]
    end
end

function Attribute.getters:textContent()
    return self.value
end

function Attribute.getters:escapedValue()
    return (self.value:gsub('[&"]', escmap):gsub("\194\160", escmap))
end

return Attribute
