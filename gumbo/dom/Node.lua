local yield, wrap = coroutine.yield, coroutine.wrap
local _ENV = nil

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

    childNodes = {length = 0}
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

return Node
