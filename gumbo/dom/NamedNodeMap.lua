local _ENV = nil
local NamedNodeMap = {}

function NamedNodeMap:__index(k)
    if k == "length" then
        return #self
    end
end

-- TODO: Add tests
function NamedNodeMap:item(index)
    return self[index]
end

return NamedNodeMap
