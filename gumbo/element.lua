local Attributes = require "gumbo.attributes"
local Element = {}
Element.__index = Element

-- Empty attributes table, shared across all elements with zero attributes
-- (helps to avoid nil checks, without consuming much extra memory).
Element.attr = Attributes.new()

return Element
