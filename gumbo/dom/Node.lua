local yield, wrap = coroutine.yield, coroutine.wrap
local tremove, error = table.remove, error
local _ENV = nil
local getters = {}

local Node = {
    ELEMENT_NODE = 1,
    ATTRIBUTE_NODE = 2, -- historical
    TEXT_NODE = 3,
    CDATA_SECTION_NODE = 4, -- historical
    ENTITY_REFERENCE_NODE = 5, -- historical
    ENTITY_NODE = 6, -- historical
    PROCESSING_INSTRUCTION_NODE = 7,
    COMMENT_NODE = 8,
    DOCUMENT_NODE = 9,
    DOCUMENT_TYPE_NODE = 10,
    DOCUMENT_FRAGMENT_NODE = 11,
    NOTATION_NODE = 12, -- historical

    childNodes = {length = 0},
    getters = getters
}

function Node:walk()
    local level = 0
    local function iter(node)
        local childNodes = node.childNodes
        local length = #childNodes
        if length > 0 then
            level = level + 1
            for index = 1, length do
                local child = childNodes[index]
                yield(child, level, index, length)
                iter(child)
            end
            level = level - 1
        end
    end
    return wrap(function() iter(self) end)
end

function Node:hasChildNodes()
    return self.childNodes[1] and true or false
end

function Node:removeChild(child)
    if child.parentNode ~= self then
        error "NotFoundError"
    end
    local childNodes = self.childNodes
    for i = 1, #childNodes do
        if childNodes[i] == child then
            tremove(childNodes, i)
            child.parentNode = nil
            return child
        end
    end
    error "NotFoundError"
end

function Node:contains(other)
    if not other then
        return false
    elseif other == self then
        return true
    elseif self:hasChildNodes() == false then
        return false
    end
    local node = other
    while node.parentNode do
        if node.parentNode == self then
            return true
        end
        node = node.parentNode
    end
    return false
end

function getters:ownerDocument()
    if self.type == "document" then
        return nil
    end
    local node = self
    while node.parentNode do
        node = node.parentNode
    end
    if node.type == "document" then
        return node
    end
end

function getters:parentElement()
    local parentNode = self.parentNode
    if parentNode and parentNode.type == "element" then
        return parentNode
    end
end

return Node
