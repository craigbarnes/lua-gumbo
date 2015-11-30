--[[
 LuaJIT FFI bindings for the Gumbo HTML5 parsing library.
 Copyright (c) 2013-2014 Craig Barnes

 Permission to use, copy, modify, and/or distribute this software for any
 purpose with or without fee is hereby granted, provided that the above
 copyright notice and this permission notice appear in all copies.

 THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
 SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION
 OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN
 CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
]]

local ffi = require "ffi"
local C = require "gumbo.ffi-cdef"
local Document = require "gumbo.dom.Document"
local DocumentType = require "gumbo.dom.DocumentType"
local DocumentFragment = require "gumbo.dom.DocumentFragment"
local Element = require "gumbo.dom.Element"
local Attribute = require "gumbo.dom.Attribute"
local Text = require "gumbo.dom.Text"
local Comment = require "gumbo.dom.Comment"
local NodeList = require "gumbo.dom.NodeList"
local AttributeList = require "gumbo.dom.AttributeList"
local GumboStringPiece = ffi.typeof "GumboStringPiece"
local have_tnew, tnew = pcall(require, "table.new")
local createtable = have_tnew and tnew or function() return {} end
local cstring, cast, new = ffi.string, ffi.cast, ffi.new
local tonumber, setmetatable, format = tonumber, setmetatable, string.format
local function oob(t, k) error(format("Index out of bounds: %s", k), 2) end
local function LookupTable(t) return setmetatable(t, {__index = oob}) end
local tagnsmap = LookupTable{"svg", "math"}
local attrnsmap = LookupTable{"xlink", "xml", "xmlns"}
local quirksmap = LookupTable{[0] = "no-quirks", "quirks", "limited-quirks"}
local namespaces = {html = 0, svg = 1, math = 2}
local constructors

local function get_attributes(attrs)
    local length = attrs.length
    if length > 0 then
        local t = createtable(length, length)
        for i = 0, length - 1 do
            local attr = cast("GumboAttribute*", attrs.data[i])
            local name = cstring(attr.name)
            local a = {
                name = name,
                value = cstring(attr.value),
                line = attr.name_start.line,
                column = attr.name_start.column,
                offset = attr.name_start.offset
            }
            if attr.attr_namespace ~= C.GUMBO_ATTR_NAMESPACE_NONE then
                a.prefix = attrnsmap[tonumber(attr.attr_namespace)]
            end
            t[i+1] = setmetatable(a, Attribute)
            t[name] = a
        end
        return setmetatable(t, AttributeList)
    end
end

local function get_tag_name(element)
    if element.tag_namespace == C.GUMBO_NAMESPACE_SVG then
        local original_tag = GumboStringPiece(element.original_tag)
        C.gumbo_tag_from_original_text(original_tag)
        local normalized = C.gumbo_normalize_svg_tagname(original_tag)
        if normalized ~= nil then
            return cstring(normalized)
        end
    end
    if element.tag == C.GUMBO_TAG_UNKNOWN then
        local original_tag = GumboStringPiece(element.original_tag)
        C.gumbo_tag_from_original_text(original_tag)
        local tag = cstring(original_tag.data, tonumber(original_tag.length))
        return tag:lower()
    else
        return cstring(C.gumbo_normalized_tagname(element.tag))
    end
end

local function add_children(parent, children, start, depth)
    local length = children.length
    assert(depth < 800, "Tree depth limit of 800 exceeded")
    local childNodes = createtable(length, 0)
    for i = 0, length - 1 do
        local node = cast("GumboNode*", children.data[i])
        local construct = constructors[tonumber(node.type)]
        local t = construct(node, depth + 1)
        t.parentNode = parent
        childNodes[i+start] = t
    end
    parent.childNodes = setmetatable(childNodes, NodeList)
end

local function create_element(node, depth)
    local element = node.v.element
    local t = {
        localName = get_tag_name(element),
        attributes = get_attributes(element.attributes),
        line = element.start_pos.line,
        column = element.start_pos.column,
        offset = element.start_pos.offset
    }
    if element.tag_namespace ~= C.GUMBO_NAMESPACE_HTML then
        t.namespace = tagnsmap[tonumber(element.tag_namespace)]
    end
    local parseFlags = tonumber(node.parse_flags)
    if parseFlags ~= 0 then
        t.parseFlags = parseFlags
    end
    add_children(t, element.children, 1, depth)
    return setmetatable(t, Element)
end

local function create_template(node, depth)
    local element = node.v.element
    local t = {
        type = "template",
        localName = "template",
        attributes = get_attributes(element.attributes),
        line = element.start_pos.line,
        column = element.start_pos.column,
        offset = element.start_pos.offset,
        childNodes = setmetatable({}, NodeList),
        content = setmetatable({}, DocumentFragment)
    }
    add_children(t.content, element.children, 1, depth)
    return setmetatable(t, Element)
end

local function make_text(node)
    local text = node.v.text
    return {
        data = cstring(text.text),
        line = text.start_pos.line,
        column = text.start_pos.column,
        offset = text.start_pos.offset
    }
end

local function create_text(node)
    local n = make_text(node)
    return setmetatable(n, Text)
end

local function create_cdata(node)
    local n = make_text(node)
    n.type = "cdata"
    return setmetatable(n, Text)
end

local function create_whitespace(node)
    local n = make_text(node)
    n.type = "whitespace"
    return setmetatable(n, Text)
end

local function create_comment(node)
    local n = make_text(node)
    return setmetatable(n, Comment)
end

constructors = LookupTable {
    create_element,
    create_text,
    create_cdata,
    create_comment,
    create_whitespace,
    create_template
}

local function create_document(document)
    local t = {}
    if document.has_doctype then
        t.quirksMode = quirksmap[tonumber(document.doc_type_quirks_mode)]
        local doctype = {
            name = cstring(document.name),
            publicId = cstring(document.public_identifier),
            systemId = cstring(document.system_identifier)
        }
        add_children(t, document.children, 2, 0)
        t.childNodes[1] = setmetatable(doctype, DocumentType)
    else
        add_children(t, document.children, 1, 0)
    end
    return setmetatable(t, Document)
end

local function parse(input, tagname, ns, tab_stop)
    assert(type(input) == "string")
    local options = new("GumboOptions", C.kGumboDefaultOptions)
    if tagname ~= nil then
        assert(type(tagname) == "string")
        options.fragment_context = C.gumbo_tag_enum(tagname)
    end
    if ns ~= nil then
        assert(type(ns) == "string")
        local validNamespace = namespaces[ns]
        if validNamespace then
            options.fragment_namespace = validNamespace
        else
            error("bad argument #3; invalid namespace '" .. ns .. "'", 2)
        end
    end
    if tab_stop ~= nil then
        assert(type(tab_stop) == "number")
        options.tab_stop = tab_stop
    end
    local output = C.gumbo_parse_with_options(options, input, #input)
    if output ~= nil then
        local ok, result = pcall(create_document, output.document.v.document)
        C.gumbo_destroy_output(options, output)
        if ok == true then
            return result
        else
            return nil, result
        end
    else
        return nil, "Failed to parse"
    end
end

return parse
