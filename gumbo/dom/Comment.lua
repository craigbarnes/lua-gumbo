local util = require "gumbo.dom.util"
local Node = require "gumbo.dom.Node"
local ChildNode = require "gumbo.dom.ChildNode"
local Text = require "gumbo.dom.Text"
local assertComment = util.assertComment
local constructor = assert(getmetatable(Text))
local setmetatable = setmetatable
local _ENV = nil

local Comment = util.merge(Node, ChildNode, {
    type = "comment",
    nodeName = "#comment",
    nodeType = 8,
    data = ""
})

function Comment:__tostring()
    assertComment(self)
    return "<!--" .. self.data .. "-->"
end

function Comment:cloneNode()
    assertComment(self)
    return setmetatable({data = self.data}, Comment)
end

function Comment.getters:length()
    return #self.data
end

return setmetatable(Comment, constructor)
