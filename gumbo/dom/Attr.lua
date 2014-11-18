local util = require "gumbo.dom.util"
local _ENV = nil

local Attr = {
    specified = true,
    getters = {}
}

Attr.__index = util.indexFactory(Attr)

function Attr.getters:localName()
    return self.name
end

function Attr.getters:textContent()
    return self.value
end

local escmap = {
    ["&"] = "&amp;",
    ['"'] = "&quot;"
}

function Attr.getters:escapedValue()
    return (self.value:gsub('[&"]', escmap):gsub("\194\160", "&nbsp;"))
end

return Attr
