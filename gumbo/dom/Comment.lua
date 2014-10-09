local util = require "gumbo.dom.util"
local setmetatable = setmetatable
local _ENV = nil

local Comment = util.merge("CharacterData", {
    type = "comment",
    nodeName = "#comment",
    nodeType = 8
})

local getters = Comment.getters or {}

function Comment:__index(k)
    local field = Comment[k]
    if field then
        return field
    else
        local getter = getters[k]
        if getter then
            return getter(self)
        end
    end
end

function Comment:cloneNode()
    return setmetatable({data = self.data}, Comment)
end

function Comment:isEqualNode(node)
    if node
        and node.nodeType == Comment.nodeType
        and self.nodeType == Comment.nodeType
        and node.data == self.data
    then
        return true
    else
        return false
    end
end

return Comment
