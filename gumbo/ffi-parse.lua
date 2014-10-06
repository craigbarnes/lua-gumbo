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
local Element = require "gumbo.dom.Element"
local Text = require "gumbo.dom.Text"
local Comment = require "gumbo.dom.Comment"
local NodeList = require "gumbo.dom.NodeList"
local GumboStringPiece = ffi.typeof "GumboStringPiece"
local have_tnew, tnew = pcall(require, "table.new")
local createtable = have_tnew and tnew or function() return {} end
local cstring, cast, new = ffi.string, ffi.cast, ffi.new
local tonumber, setmetatable = tonumber, setmetatable
local w3 = "http://www.w3.org/"
local tagnsmap = {w3.."2000/svg", w3.."1998/Math/MathML"}
local attrnsmap = {"xlink", "xml", "xmlns"}
local quirksmap = {[0] = "no-quirks", "quirks", "limited-quirks"}
local create_node

local function get_attributes(attrs)
    local length = attrs.length
    if length > 0 then
        local t = createtable(length, length)
        for i = 0, length - 1 do
            local attr = cast("GumboAttribute*", attrs.data[i])
            local name = cstring(attr.name)
            local value = cstring(attr.value)
            t[i+1] = {
                name = name,
                value = value,
                prefix = attrnsmap[tonumber(attr.attr_namespace)],
                line = attr.name_start.line,
                column = attr.name_start.column,
                offset = attr.name_start.offset
            }
            t[name] = t[i+1]
        end
        return t
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

local function add_children(t, list)
    local length = list.length
    if length > 0 then
        local nodes = createtable(length, 0)
        for i = 0, length - 1 do
            local node = create_node(cast("GumboNode*", list.data[i]))
            node.parentNode = t
            nodes[i+1] = node
        end
        setmetatable(nodes, NodeList)
        t.childNodes = nodes
    end
end

local function create_document(node)
    local document = node.v.document
    local t = {
        quirksMode = quirksmap[tonumber(document.doc_type_quirks_mode)]
    }
    if document.has_doctype then
        t.doctype = {
            name = cstring(document.name),
            publicId = cstring(document.public_identifier),
            systemId = cstring(document.system_identifier)
        }
    end
    add_children(t, document.children)
    return setmetatable(t, Document)
end

local function create_element(node)
    local element = node.v.element
    local t = {
        namespaceURI = tagnsmap[tonumber(element.tag_namespace)],
        localName = get_tag_name(element),
        attributes = get_attributes(element.attributes),
        line = element.start_pos.line,
        column = element.start_pos.column,
        offset = element.start_pos.offset
    }
    local parseFlags = tonumber(node.parse_flags)
    if parseFlags ~= 0 then
        t.parseFlags = parseFlags
    end
    add_children(t, element.children)
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

local typemap = setmetatable({
    create_element,
    create_text,
    create_cdata,
    create_comment,
    create_whitespace,
}, {__index = function() error "Error: invalid node type" end})

create_node = function(node)
    return typemap[tonumber(node.type)](node)
end

local function parse(input, tab_stop)
    assert(type(input) == "string")
    assert(type(tab_stop) == "number" or tab_stop == nil)
    local options = new("GumboOptions", C.kGumboDefaultOptions)
    options.tab_stop = tab_stop or 8
    local output = C.gumbo_parse_with_options(options, input, #input)
    local document = create_document(output.document)
    local rootIndex = tonumber(output.root.index_within_parent) + 1
    document.documentElement = document.childNodes[rootIndex]
    C.gumbo_destroy_output(options, output)
    return document
end

return parse
