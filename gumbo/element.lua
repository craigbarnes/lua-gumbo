local Attributes = require "gumbo.attributes"
local Element = {}
Element.__index = Element

-- Element nodes with attributes have an `attr` table added by the tree
-- constructor. Those without attributes share a default, empty table
-- via the metatable, to avoid the need for nil-checking in client code.
Element.attr = Attributes.new()

return Element
