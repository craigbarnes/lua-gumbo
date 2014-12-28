local util = require "gumbo.dom.util"
local _ENV = nil
local NodeList = {getters = {}}
NodeList.__index = util.indexFactory(NodeList)

-- TODO: Add tests
function NodeList:item(index)
    return self[index]
end

function NodeList:removeAll()
    for i = #self, 1, -1 do
        self[i] = nil
    end
end

function NodeList.getters:length()
    return #self
end

return NodeList
