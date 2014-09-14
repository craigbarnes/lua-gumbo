local NodeList = {}

function NodeList:__index(k)
    if k == "length" then
        return #self
    end
end

return NodeList
