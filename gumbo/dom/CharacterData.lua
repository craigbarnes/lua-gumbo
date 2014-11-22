local util = require "gumbo.dom.util"
local _ENV = nil

local CharacterData = util.merge("Node", "ChildNode", {
    data = ""
})

function CharacterData.getters:length()
    return #self.data
end

-- TODO: function CharacterData:substringData(offset, count)
-- TODO: function CharacterData:appendData(data)
-- TODO: function CharacterData:insertData(offset, data)
-- TODO: function CharacterData:deleteData(offset, count)
-- TODO: function CharacterData:replaceData(offset, count, data)

return CharacterData
