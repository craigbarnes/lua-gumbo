local CharacterData = require "gumbo.dom.CharacterData"
local util = require "gumbo.dom.util"

local Text = util.clone(CharacterData)
Text.__index = Text
Text.type = "text"

return Text
