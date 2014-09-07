local Node = require "gumbo.dom.Node"
local util = require "gumbo.dom.util"

local Text = util.clone(Node)
Text.__index = Text
Text.type = "text"

return Text
