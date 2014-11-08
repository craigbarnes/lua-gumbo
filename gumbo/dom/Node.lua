local NodeList = require "gumbo.dom.NodeList"
local Set = require "gumbo.Set"
local yield, wrap = coroutine.yield, coroutine.wrap
local tremove, assert, setmetatable = table.remove, assert, setmetatable
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

    DOCUMENT_POSITION_DISCONNECTED = 0x01,
    DOCUMENT_POSITION_PRECEDING = 0x02,
    DOCUMENT_POSITION_FOLLOWING = 0x04,
    DOCUMENT_POSITION_CONTAINS = 0x08,
    DOCUMENT_POSITION_CONTAINED_BY = 0x10,
    DOCUMENT_POSITION_IMPLEMENTATION_SPECIFIC = 0x20,
    -- TODO: function Node:compareDocumentPosition(other)

    childNodes = setmetatable({length = 0}, NodeList),
    getters = {},
    setters = {},
    readonly = Set {
        "nodeType", "nodeName", "ownerDocument", "parentElement",
        "firstChild", "lastChild", "previousSibling", "nextSibling"
    }
}

local isTextOrComment = Set {
    Node.TEXT_NODE,
    Node.COMMENT_NODE
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

function Node:reverseWalk()
    local function iter(node)
        local childNodes = node.childNodes
        local length = #childNodes
        if length > 0 then
            for index = length, 1, -1 do
                local child = childNodes[index]
                yield(child)
                iter(child)
            end
        end
    end
    return wrap(function() iter(self) end)
end

function Node:hasChildNodes()
    return self.childNodes[1] and true or false
end

function Node:removeChild(child)
    assert(child.parentNode == self, "NotFoundError")
    local childNodes = self.childNodes
    for i = 1, #childNodes do
        if childNodes[i] == child then
            tremove(childNodes, i)
            child.parentNode = nil
            return child
        end
    end
    assert(false, "NotFoundError")
end

function Node:contains(other)
    if not other or not other.nodeType then
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

function Node.getters:ownerDocument()
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

function Node.getters:parentElement()
    local parentNode = self.parentNode
    if parentNode and parentNode.type == "element" then
        return parentNode
    end
end

function Node.getters:firstChild()
    return self.childNodes[1]
end

function Node.getters:lastChild()
    local cnodes = self.childNodes
    return cnodes[#cnodes]
end

function Node.getters:previousSibling()
    local parentNode = self.parentNode
    if parentNode then
        local siblings = parentNode.childNodes
        for i = 1, #siblings do
            if siblings[i] == self and i > 1 then
                return siblings[i-1]
            end
        end
    end
end

function Node.getters:nextSibling()
    local parentNode = self.parentNode
    if parentNode then
        local siblings = parentNode.childNodes
        for i = 1, #siblings do
            if siblings[i] == self then
                return siblings[i+1]
            end
        end
    end
end

-- TODO: implement setter
function Node.getters:nodeValue()
    if isTextOrComment[self.nodeType] then
        return self.data
    end
end

local function hasbit(flags, bit)
  return (flags and flags % (bit * 2) >= bit) and true or false
end

function Node.getters:insertedByParser()
    return hasbit(self.parseFlags, 1)
end

function Node.getters:implicitEndTag()
    return hasbit(self.parseFlags, 2)
end

return Node
