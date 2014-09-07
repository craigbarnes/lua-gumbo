local util = require "gumbo.dom.util"

local Comment = util.implements("CharacterData")
Comment.type = "comment"

return Comment
