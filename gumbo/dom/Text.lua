local util = require "gumbo.dom.util"
local setmetatable = setmetatable
local _ENV = nil

local Text = util.merge("CharacterData", {
    type = "text",
    nodeName = "#text",
    nodeType = 3
})

local getters = Text.getters

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

function Text:new(data)
    return setmetatable({data = data}, Text)
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

function Text.getters:escapedData()
    return (self.data:gsub("[&<>]", escmap):gsub("\xC2\xA0", "&nbsp;"))
end

return setmetatable(Text, {__call = Text.new})
