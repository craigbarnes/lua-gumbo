local util = require "gumbo.dom.util"
local NodeList = require "gumbo.dom.NodeList"
local Buffer = require "gumbo.Buffer"
local Set = require "gumbo.Set"
local assertNode = util.assertNode
local assertStringOrNil = util.assertStringOrNil
local yield, wrap = coroutine.yield, coroutine.wrap
local tinsert, tremove = table.insert, table.remove
local ipairs, type, error, assert = ipairs, type, error, assert
local setmetatable = setmetatable
local _ENV = nil

local Node = {
    ELEMENT_NODE = 1,
    TEXT_NODE = 3,
    PROCESSING_INSTRUCTION_NODE = 7,
    COMMENT_NODE = 8,
    DOCUMENT_NODE = 9,
    DOCUMENT_TYPE_NODE = 10,
    DOCUMENT_FRAGMENT_NODE = 11,

    childNodes = setmetatable({length = 0}, {
        __index = NodeList,
        __newindex = function() error("childNodes field is read-only", 2) end
    }),

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

local isCharacterData = Set {
    Node.TEXT_NODE,
    Node.COMMENT_NODE,
    Node.PROCESSING_INSTRUCTION_NODE
}

local isElementOrDocumentFragment = Set {
    Node.DOCUMENT_FRAGMENT_NODE,
    Node.ELEMENT_NODE
}

local isValidParent = Set {
    Node.DOCUMENT_NODE,
    Node.DOCUMENT_FRAGMENT_NODE,
    Node.ELEMENT_NODE
}

local isValidChild = Set {
    Node.DOCUMENT_FRAGMENT_NODE,
    Node.DOCUMENT_TYPE_NODE,
    Node.ELEMENT_NODE,
    Node.TEXT_NODE,
    Node.PROCESSING_INSTRUCTION_NODE,
    Node.COMMENT_NODE
}

function Node:walk()
    assertNode(self)
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
    assertNode(self)
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
    assertNode(self)
    return self.childNodes[1] and true or false
end

local function isEqualElement(self, other)
    local selfAttrs = self.attributes
    local otherAttrs = other.attributes
    if
        self.namespace ~= other.namespace
        -- TODO: namespace prefix
        or self.localName ~= other.localName
        or selfAttrs.length ~= otherAttrs.length
    then
        return false
    end
    for i, attrA in ipairs(selfAttrs) do
        local attrB = otherAttrs[i]
        if
            -- TODO: namespace
            attrA.localName ~= attrB.localName
            or attrA.value ~= attrB.value
        then
            return false
        end
    end
    return true
end

local function isEqualDoctype(self, other)
    return
        self.name == other.name
        and self.publicID == other.publicID
        and self.systemID == other.systemID
end

local function isEqualText(self, other)
    return other.data == self.data
end

local comparators = {
    [Node.ELEMENT_NODE] = isEqualElement,
    [Node.DOCUMENT_TYPE_NODE] = isEqualDoctype,
    [Node.TEXT_NODE] = isEqualText,
    [Node.COMMENT_NODE] = isEqualText
}

-- https://dom.spec.whatwg.org/#dom-node-isequalnode
function Node:isEqualNode(other)
    assertNode(self)
    if other == self then
        -- This step does not appear in the spec, but if two tables compare
        -- equal by identity, we can just return true here, since they
        -- certainly compare equal according to the remaining steps.
        return true
    end
    if not other or type(other) ~= "table" then
        return false
    end
    if other.nodeType ~= self.nodeType then
        return false
    end
    local comparator = comparators[self.nodeType]
    if comparator and comparator(self, other) == false then
        return false
    end
    local selfChildNodes = self.childNodes
    local otherChildNodes = other.childNodes
    if otherChildNodes.length ~= selfChildNodes.length then
        return false
    end
    for i, childA in ipairs(selfChildNodes) do
        local childB = otherChildNodes[i]
        if childA:isEqualNode(childB) == false then
            return false
        end
    end
    return true
end

-- TODO: function Node:cloneNode(deep)

-- TODO: Node.baseURI
-- TODO: function Node:replaceChild(node, child)
-- TODO: function Node:normalize()
-- TODO: function Node:compareDocumentPosition(other)
-- TODO: function Node:lookupPrefix(namespace)
-- TODO: function Node:lookupNamespaceURI(prefix)
-- TODO: function Node:isDefaultNamespace(namespace)

local function getChildIndex(parent, child)
    for i, node in ipairs(parent.childNodes) do
        if node == child then
            return i
        end
    end
    return nil, "NotFoundError"
end

-- https://dom.spec.whatwg.org/#concept-node-ensure-pre-insertion-validity
local function ensurePreInsertionValidity(node, parent, child)
    assert(isValidParent[parent.nodeType] == true, "HierarchyRequestError")
    assert(parent ~= node, "HierarchyRequestError")
    assert(node:contains(parent) == false, "HierarchyRequestError")
    assert(child == nil or child.parentNode == parent, "NotFoundError")
    assert(isValidChild[node.nodeType] == true, "HierarchyRequestError")

    if parent.type == "document" then
        assert(node.nodeName ~= "#text", "HierarchyRequestError")
    else
        assert(node.type ~= "doctype", "HierarchyRequestError")
    end

    if parent.type == "document" then
        -- TODO: Implement the steps for DocumentFragment nodes, when they
        --       are supported.

        local parentHasElementChild = parent.firstElementChild and true or false

        if node.type == "element" then
            if parentHasElementChild == true
            or child.type == "doctype"
            -- TODO: "or child is not null and a doctype is following child"
            then
                assert(false, "HierarchyRequestError")
            end
        end

        if node.type == "doctype" then
            if parent.doctype
            -- TODO: "an element is preceding child"
            or (child == nil and parentHasElementChild == true)
            then
                assert(false, "HierarchyRequestError")
            end
        end
    end
end

-- https://dom.spec.whatwg.org/#concept-node-pre-insert
local function preInsert(node, parent, child)
    ensurePreInsertionValidity(node, parent, child)
    local referenceChild = child
    if referenceChild == node then
        referenceChild = node.nextSibling
    end
    parent.ownerDocument:adoptNode(node)
    -- TODO: Implement https://dom.spec.whatwg.org/#concept-node-insert
    --       when DocumentFragment support is added.
    local childNodes = assert(parent.childNodes)
    if referenceChild == nil then
        childNodes[childNodes.length + 1] = node
    else
        local index = assert(getChildIndex(parent, referenceChild))
        tinsert(childNodes, index, node)
    end
    node.parentNode = parent
    return node
end

function Node:appendChild(node)
    assertNode(self)
    assertNode(node)
    return preInsert(node, self)
end

function Node:insertBefore(node, child)
    assertNode(self)
    assertNode(node)
    if child ~= nil then
        assertNode(child)
    end
    return preInsert(node, self, child)
end

function Node:removeChild(child)
    assertNode(self)
    assertNode(child)
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
    assertNode(self)
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

function Node.getters:textContent()
    local nodeType = self.nodeType
    if isCharacterData[nodeType] then
        return self.data
    elseif isElementOrDocumentFragment[nodeType] then
        local buffer = Buffer()
        for node in self:walk() do
            if node.nodeName == "#text" then
                buffer:write(node.data)
            end
        end
        return buffer:tostring()
    end
end

function Node.setters:textContent(value)
    assertStringOrNil(value)
    local nodeType = self.nodeType
    if isCharacterData[nodeType] then
        self.data = value
    elseif isElementOrDocumentFragment[nodeType] then
        self.childNodes:removeAll()
        if value then
            local node = self.ownerDocument:createTextNode(value)
            self:appendChild(node)
        end
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
