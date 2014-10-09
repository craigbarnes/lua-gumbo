local ipairs = ipairs
local _ENV = nil
local getters = {}
local ParentNode = {getters = getters}

function getters:children()
    if self:hasChildNodes() then
        local collection = {}
        local length = 0
        for i, node in ipairs(self.childNodes) do
            if node.type == "element" then
                length = length + 1
                collection[length] = node
            end
        end
        collection.length = length
        return collection
    end
end

function getters:childElementCount()
    local length = 0
    if self:hasChildNodes() then
        for i, node in ipairs(self.childNodes) do
            if node.type == "element" then
                length = length + 1
            end
        end
    end
    return length
end

-- function getters:firstElementChild() end
-- function getters:lastElementChild() end

-- function ParentNode:append(...) end
-- function ParentNode:prepend(...) end
-- function ParentNode:query(relativeSelectors) end
-- function ParentNode:queryAll(relativeSelectors) end
-- function ParentNode:querySelector(selectors) end
-- function ParentNode:querySelectorAll(selectors) end

return ParentNode
