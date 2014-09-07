local Node = require "gumbo.dom.Node"
local ChildNode = require "gumbo.dom.ChildNode"
local util = require "gumbo.dom.util"

local CharacterData = util.clone(Node)
CharacterData.__index = CharacterData

CharacterData.remove = ChildNode.remove -- TODO: use "implements" function

return CharacterData
