local util = require "gumbo.dom.util"
local assert = assert
local _ENV = nil

local Attr = {getters = {}}
Attr.__index = assert(util.indexFactory(Attr))

local escmap = {
    ["\194\160"] = "&nbsp;",
    ["&"] = "&amp;",
    ['"'] = "&quot;"
}

function Attr.getters:localName()
    return self.name
end

function Attr.getters:textContent()
    return self.value
end

function Attr.getters:escapedValue()
    return (self.value:gsub('[&"]', escmap):gsub("\194\160", escmap))
end

return Attr
