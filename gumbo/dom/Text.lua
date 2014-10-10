local util = require "gumbo.dom.util"
local setmetatable = setmetatable
local _ENV = nil

local Text = util.merge("CharacterData", {
    type = "text",
    nodeName = "#text",
    nodeType = 3
})

local getters = Text.getters or {}

function Text:__index(k)
    local field = Text[k]
    if field then
        return field
    else
        local getter = getters[k]
        if getter then
            return getter(self)
        end
    end
end

function Text:cloneNode()
    return setmetatable({data = self.data}, Text)
end

function Text:isEqualNode(node)
    if node
        and node.nodeType == Text.nodeType
        and self.nodeType == Text.nodeType
        and node.data == self.data
    then
        return true
    else
        return false
    end
end

local escmap = {
    ["&"] = "&amp;",
    ["<"] = "&lt;",
    [">"] = "&gt;",
}

function getters:escapedData()
    return (self.data:gsub("[&<>]", escmap):gsub("\xC2\xA0", "&nbsp;"))
end

return Text
