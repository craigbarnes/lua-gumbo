local NodeList = require "gumbo.dom.NodeList"
local Set = require "gumbo.Set"
local assertions = require "gumbo.dom.assertions"
local assertNode = assertions.assertNode
local yield, wrap = coroutine.yield, coroutine.wrap
local tinsert, tremove = table.insert, table.remove
local ipairs, type, error, assert = ipairs, type, error, assert
local setmetatable = setmetatable
local _ENV = nil

local Node = {
    -- Valid node types
    ELEMENT_NODE = 1,
    TEXT_NODE = 3,
    PROCESSING_INSTRUCTION_NODE = 7,
    COMMENT_NODE = 8,
    DOCUMENT_NODE = 9,
    DOCUMENT_TYPE_NODE = 10,
    DOCUMENT_FRAGMENT_NODE = 11,

    -- Obsolete node types
    ATTRIBUTE_NODE = 2,
    CDATA_SECTION_NODE = 4,
    ENTITY_REFERENCE_NODE = 5,
    ENTITY_NODE = 6,
    NOTATION_NODE = 12,

    DOCUMENT_POSITION_DISCONNECTED = 0x01,
    DOCUMENT_POSITION_PRECEDING = 0x02,
    DOCUMENT_POSITION_FOLLOWING = 0x04,
    DOCUMENT_POSITION_CONTAINS = 0x08,
    DOCUMENT_POSITION_CONTAINED_BY = 0x10,
    DOCUMENT_POSITION_IMPLEMENTATION_SPECIFIC = 0x20,

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

local comparators = {}

comparators[Node.ELEMENT_NODE] = function(self, other)
    local selfAttrs = self.attributes
    local otherAttrs = other.attributes
    if
        self.namespaceURI ~= other.namespaceURI
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

comparators[Node.DOCUMENT_TYPE_NODE] = function(self, other)
    return
        self.name == other.name
        and self.publicID == other.publicID
        and self.systemID == other.systemID
end

comparators[Node.TEXT_NODE] = function(self, other)
    return other.data == self.data
end

comparators[Node.COMMENT_NODE] = comparators[Node.TEXT_NODE]

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

-- TODO: Node.textContent
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
    -- 1. If parent is not a Document, DocumentFragment, or Element
    --    node, throw a HierarchyRequestError.
    assert(isValidParent[parent.nodeType] == true, "HierarchyRequestError")

    -- 2. If node is a host-including inclusive ancestor of parent,
    --    throw a HierarchyRequestError.
    assert(parent ~= node, "HierarchyRequestError")
    assert(node:contains(parent) == false, "HierarchyRequestError")

    -- 3. If child is not null and its parent is not parent, throw a
    --    NotFoundError exception.
    assert(child == nil or child.parentNode == parent, "NotFoundError")

    -- 4. If node is not a DocumentFragment, DocumentType, Element,
    --    Text, ProcessingInstruction, or Comment node, throw a
    --    HierarchyRequestError.
    assert(isValidChild[node.nodeType] == true, "HierarchyRequestError")

    -- 5. If either node is a Text node and parent is a document, or
    --    node is a doctype and parent is not a document, throw a
    --    HierarchyRequestError.
    if parent.type == "document" then
        assert(node.nodeName ~= "#text", "HierarchyRequestError")
    else
        assert(node.type ~= "doctype", "HierarchyRequestError")
    end

    -- 6. If parent is a document ...
    if parent.type == "document" then
        -- and any of the statements below, switched on node, are true,
        -- throw a HierarchyRequestError.

        -- TODO: Implement this when DocumentFragment types are supported
        -- >> DocumentFragment node
        -- * If node has more than one element child or has a Text node child.
        -- * Otherwise, if node has one element child and either parent has
        --   an element child, child is a doctype, or child is not null and
        --   a doctype is following child.

        local parentHasElementChild = parent.firstElementChild and true or false

        -- >> element
        if node.type == "element" then
            -- parent has an element child,
            if parentHasElementChild == true
            -- child is a doctype,
            or child.type == "doctype"
            -- or child is not null and a doctype is following child.
            -- TODO
            then
                assert(false, "HierarchyRequestError")
            end
        end

        -- >> doctype
        if node.type == "doctype" then
            -- parent has a doctype child,
            if parent.doctype
            -- an element is preceding child,
            -- TODO
            -- or child is null and parent has an element child.
            or (child == nil and parentHasElementChild == true)
            then
                assert(false, "HierarchyRequestError")
            end
        end
    end
end

-- https://dom.spec.whatwg.org/#concept-node-pre-insert
local function preInsert(node, parent, child)
    -- 1. Ensure pre-insertion validity of node into parent before child.
    ensurePreInsertionValidity(node, parent, child)

    -- 2. Let reference child be child.
    local referenceChild = child

    -- 3. If reference child is node, set it to node's next sibling.
    if referenceChild == node then
        referenceChild = node.nextSibling
    end

    -- 4. Adopt node into parent's node document.
    parent.ownerDocument:adoptNode(node)

    -- 5. Insert node into parent before reference child.
    -- TODO: Implement https://dom.spec.whatwg.org/#concept-node-insert
    local childNodes = assert(parent.childNodes)
    local index
    if referenceChild == nil then
        index = childNodes.length + 1
    else
        index = assert(getChildIndex(parent, referenceChild))
    end
    tinsert(childNodes, index, node)
    node.parentNode = parent

    -- 6. Return node.
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

function Node.getters:nodeValue()
    if isTextOrComment[self.nodeType] then
        return self.data
    end
end

-- TODO: function Node.setters:nodeValue(value)

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
