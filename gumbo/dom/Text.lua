local util = require "gumbo.dom.util"
local assertions = require "gumbo.dom.assertions"
local assertTextNode = assertions.assertTextNode
local assertNilableString = assertions.assertNilableString
local setmetatable = setmetatable
local _ENV = nil

local Text = util.merge("Node", "ChildNode", {
    type = "text",
    nodeName = "#text",
    nodeType = 3,
    data = ""
})

function Text:__tostring()
    assertTextNode(self)
    return '#text "' .. self.data .. '"'
end

function Text:cloneNode()
    assertTextNode(self)
    return setmetatable({data = self.data}, Text)
end

function Text.getters:length()
    return #self.data
end

local escmap = {
    ["&"] = "&amp;",
    ["<"] = "&lt;",
    [">"] = "&gt;",
}

function Text.getters:escapedData()
    return (self.data:gsub("[&<>]", escmap):gsub("\194\160", "&nbsp;"))
end

local constructor = {
    __call = function(self, data)
        assertNilableString(data)
        return setmetatable({data = data}, self)
    end
}

return setmetatable(Text, constructor)
