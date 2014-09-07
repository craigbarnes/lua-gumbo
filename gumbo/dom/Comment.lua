local CharacterData = require "gumbo.dom.CharacterData"
local util = require "gumbo.dom.util"

local Comment = util.clone(CharacterData)
Comment.__index = Comment
Comment.type = "comment"

return Comment
