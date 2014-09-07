local util = require "gumbo.dom.util"

local Comment = util.implements("CharacterData")
Comment.type = "comment"
Comment.nodeName = "#comment"
Comment.nodeType = 8

return Comment
