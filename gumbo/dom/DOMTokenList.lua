local util = require "gumbo.dom.util"
local Buffer = require "gumbo.Buffer"
local assertString = util.assertString
local error = error
local _ENV = nil
local DOMTokenList = {}
DOMTokenList.__index = DOMTokenList

-- TODO: Add type assertions
-- TODO: function DOMTokenList:add(...)
-- TODO: function DOMTokenList:remove(...)
-- TODO: function DOMTokenList:toggle(token, force)

function DOMTokenList:__tostring()
    local length = self.length
    local buf = Buffer()
    buf:write("DOMTokenList{")
    if length > 0 then
        buf:write('"', self[1], '"')
        for i = 2, length do
            buf:write(', "', self[i], '"')
        end
    end
    buf:write("}")
    return buf:tostring()
end

function DOMTokenList:toString()
    local buf = Buffer()
    for i = 1, self.length do
        buf:write(self[i])
    end
    return buf:tostring()
end

function DOMTokenList:item(index)
    return self[index]
end

function DOMTokenList:contains(token)
    assertString(token)
    if token == "" then
        error("SyntaxError", 2)
    elseif token:find("%s") then
        error("InvalidCharacterError", 2)
    elseif self[token] then
        return true
    else
        return false
    end
end

return DOMTokenList
