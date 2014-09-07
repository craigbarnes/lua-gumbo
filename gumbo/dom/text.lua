local Node = require "gumbo.dom.node"
local util = require "gumbo.dom.util"

local Text = util.clone(Node)
Text.__index = Text
Text.type = "text"

return Text
