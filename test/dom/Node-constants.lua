local gumbo = require "gumbo"
local Node = require "gumbo.dom.Node"
local Document = require "gumbo.dom.Document"
local Element = require "gumbo.dom.Element"
local Text = require "gumbo.dom.Text"
local Comment = require "gumbo.dom.Comment"
local DocumentType = require "gumbo.dom.DocumentType"
local pairs, ipairs, assert, error = pairs, ipairs, assert, error
local _ENV = nil

local input = "<!doctype html><title>Node constants</title>"
local document = assert(gumbo.parse(input))

local constants = {
    ELEMENT_NODE = 1,
    ATTRIBUTE_NODE = 2,
    TEXT_NODE = 3,
    CDATA_SECTION_NODE = 4,
    ENTITY_REFERENCE_NODE = 5,
    ENTITY_NODE = 6,
    PROCESSING_INSTRUCTION_NODE = 7,
    COMMENT_NODE = 8,
    DOCUMENT_NODE = 9,
    DOCUMENT_TYPE_NODE = 10,
    DOCUMENT_FRAGMENT_NODE = 11,
    NOTATION_NODE = 12,
    DOCUMENT_POSITION_DISCONNECTED = 0x01,
    DOCUMENT_POSITION_PRECEDING = 0x02,
    DOCUMENT_POSITION_FOLLOWING = 0x04,
    DOCUMENT_POSITION_CONTAINS = 0x08,
    DOCUMENT_POSITION_CONTAINED_BY = 0x10,
    DOCUMENT_POSITION_IMPLEMENTATION_SPECIFIC = 0x20
}

local objects = {
    {Node, "Node interface object"},
    {Document, "Document interface object"},
    {Element, "Element interface object"},
    {Text, "Text interface object"},
    {Comment, "Comment interface object"},
    {DocumentType, "DocumentType interface object"},
    {document, "Document object"},
    {document:createElement("foo"), "Element object"},
    {document:createTextNode("bar"), "Text object"},
    {document:createComment("baz"), "Comment object"},
    {document.doctype, "DocumentType object"}
}

for i, t in ipairs(objects) do
    local object, name = assert(t[1]), assert(t[2])
    for constant, expected in pairs(constants) do
        local found = object[constant]
        if not found then
            local message = "%s field is missing for %s"
            error(message:format(constant, name))
        elseif found ~= expected then
            local message = "%s field in %s has unexpected value"
            error(message:format(constant, name))
        end
    end
end
