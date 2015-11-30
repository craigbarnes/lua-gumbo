local _ENV = nil
local AttributeList = {}

function AttributeList:__index(k)
    if k == "length" then
        return #self
    end
end

-- TODO: Add tests
function AttributeList:item(index)
    return self[index]
end

-- TODO: function AttributeList:getNamedItem(name)
-- TODO: function AttributeList:getNamedItemNS(namespace, localName)
-- TODO: function AttributeList:setNamedItem(attr)
-- TODO: function AttributeList:setNamedItemNS(attr)
-- TODO: function AttributeList:removeNamedItem(name)
-- TODO: function AttributeList:removeNamedItemNS(namespace, localName)

return AttributeList
