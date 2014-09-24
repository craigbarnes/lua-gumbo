local util = require "gumbo.dom.util"

local Text = util.merge("CharacterData", {
    type = "text",
    nodeName = "#text",
    nodeType = 3
})

function Text:cloneNode()
    return setmetatable({data = self.data}, Text)
end

return Text
