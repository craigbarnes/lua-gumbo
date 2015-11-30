local ElementList = require "gumbo.dom.ElementList"
local Set = require "gumbo.Set"
local ipairs, setmetatable = ipairs, setmetatable
local _ENV = nil

local ParentNode = {
    getters = {},
    readonly = Set {
        "children", "firstElementChild", "lastElementChild",
        "childElementCount"
    }
}

function ParentNode.getters:children()
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
        return setmetatable(collection, ElementList)
    end
end

function ParentNode.getters:childElementCount()
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

function ParentNode.getters:firstElementChild()
    if self:hasChildNodes() then
        for i, node in ipairs(self.childNodes) do
            if node.type == "element" then
                return node
            end
        end
    end
end

function ParentNode.getters:lastElementChild()
    if self:hasChildNodes() then
        local childNodes = self.childNodes
        for i = #childNodes, 1, -1 do
            local node = childNodes[i]
            if node.type == "element" then
                return node
            end
        end
    end
end

-- TODO: function ParentNode:append(...)
-- TODO: function ParentNode:prepend(...)
-- TODO: function ParentNode:query(relativeSelectors)
-- TODO: function ParentNode:queryAll(relativeSelectors)
-- TODO: function ParentNode:querySelector(selectors)
-- TODO: function ParentNode:querySelectorAll(selectors)

return ParentNode
