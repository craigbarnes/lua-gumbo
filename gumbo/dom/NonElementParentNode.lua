local assert = assert
local _ENV = nil
local NonElementParentNode = {}

function NonElementParentNode:getElementById(elementId)
    assert(self.childNodes, "Invalid self argument")
    for node in self:walk() do
        if node.type == "element" then
            local attr = node.attributes
            if attr.id and attr.id.value == elementId then
                return node
            end
        end
    end
end

return NonElementParentNode
