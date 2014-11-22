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

-- TODO: function NamedNodeMap:getNamedItem(name)
-- TODO: function NamedNodeMap:getNamedItemNS(namespace, localName)
-- TODO: function NamedNodeMap:setNamedItem(attr)
-- TODO: function NamedNodeMap:setNamedItemNS(attr)
-- TODO: function NamedNodeMap:removeNamedItem(name)
-- TODO: function NamedNodeMap:removeNamedItemNS(namespace, localName)

return NamedNodeMap
