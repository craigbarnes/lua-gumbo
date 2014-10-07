local util = require "gumbo.dom.util"
local setmetatable = setmetatable
local _ENV = nil

local Text = util.merge("CharacterData", {
    type = "text",
    nodeName = "#text",
    nodeType = 3
})

local getters = Text.getters or {}

function Text:__index(k)
    local field = Text[k]
    if field then
        return field
    else
        local getter = getters[k]
        if getter then
            return getter(self)
        end
    end
end

function Text:cloneNode()
    return setmetatable({data = self.data}, Text)
end

return Text
