local _ENV = nil
local NodeList = {}

function NodeList:__index(k)
    if k == "length" then
        return #self
    end
end

-- TODO: Add tests
function NodeList:item(index)
    return self[index]
end

return NodeList
