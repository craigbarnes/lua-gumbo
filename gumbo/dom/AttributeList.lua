local _ENV = nil
local AttributeList = {}

function AttributeList:__index(k)
    if k == "length" then
        return #self
    end
end

return AttributeList
