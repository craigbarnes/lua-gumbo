local Node = require "gumbo.dom.node"
local util = require "gumbo.dom.util"

local Comment = util.clone(Node)
Comment.__index = Comment
Comment.type = "comment"

return Comment
