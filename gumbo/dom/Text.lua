local util = require "gumbo.dom.util"

local Text = util.implements("CharacterData")
Text.type = "text"

return Text
