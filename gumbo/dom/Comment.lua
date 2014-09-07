local Node = require "gumbo.dom.Node"
local util = require "gumbo.dom.util"

local Comment = util.clone(Node)
Comment.__index = Comment
Comment.type = "comment"

return Comment
