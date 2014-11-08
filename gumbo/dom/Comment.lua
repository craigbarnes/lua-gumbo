local util = require "gumbo.dom.util"
local setmetatable = setmetatable
local _ENV = nil

local Comment = util.merge("CharacterData", {
    type = "comment",
    nodeName = "#comment",
    nodeType = 8
})

Comment.__index = util.indexFactory(Comment)

function Comment:new(data)
    return setmetatable({data = data}, Comment)
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

return setmetatable(Comment, {__call = Comment.new})
