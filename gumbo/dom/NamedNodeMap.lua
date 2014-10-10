local _ENV = nil
local NamedNodeMap = {}

function NamedNodeMap:__index(k)
    if k == "length" then
        return #self
    end
end

return NamedNodeMap
