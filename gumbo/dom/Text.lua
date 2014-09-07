local util = require "gumbo.dom.util"

local Text = util.implements("CharacterData")
Text.type = "text"
Text.nodeName = "#text"
Text.nodeType = 3

return Text
