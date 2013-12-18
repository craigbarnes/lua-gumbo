--[[
 LuaJIT FFI/luaffi bindings for the Gumbo HTML5 parsing library.
 Copyright (c) 2013 Craig Barnes

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
local C = require "gumbo.cdef"
local ffi_string = ffi.string
local ffi_cast = ffi.cast
local tonumber = tonumber
local create_node

local have_tnew, tnew = pcall(require, "table.new")
tnew = have_tnew and tnew or function(narr, nrec) return {} end

local have_bit, bit = pcall(require, "bit")
local testflag
if have_bit == true then
    testflag = function(value, flag)
        return bit.band(value, flag) ~= 0
    end
else
    testflag = function(value, flag)
        return value % (2 * flag) >= flag
    end
end

local typemap = {
    [tonumber(C.GUMBO_NODE_DOCUMENT)] = "document",
    [tonumber(C.GUMBO_NODE_ELEMENT)] = "element",
    [tonumber(C.GUMBO_NODE_TEXT)] = "text",
    [tonumber(C.GUMBO_NODE_CDATA)] = "cdata",
    [tonumber(C.GUMBO_NODE_COMMENT)] = "comment",
    [tonumber(C.GUMBO_NODE_WHITESPACE)] = "whitespace",
    __index = function() error "Error: invalid node type" end
}

local quirksmap = {
    [tonumber(C.GUMBO_DOCTYPE_NO_QUIRKS)] = "no-quirks",
    [tonumber(C.GUMBO_DOCTYPE_QUIRKS)] = "quirks",
    [tonumber(C.GUMBO_DOCTYPE_LIMITED_QUIRKS)] = "limited-quirks",
    __index = function() error "Error: invalid quirks mode" end
}

local tagnsmap = {
    [C.GUMBO_NAMESPACE_SVG] = "svg",
    [C.GUMBO_NAMESPACE_MATHML] = "math"
}

local attrnsmap = {
    [C.GUMBO_ATTR_NAMESPACE_XLINK] = "xlink",
    [C.GUMBO_ATTR_NAMESPACE_XML] = "xml",
    [C.GUMBO_ATTR_NAMESPACE_XMLNS] = "xmlns"
}

local flagsmap = {
    insertion_by_parser = C.GUMBO_INSERTION_BY_PARSER,
    implicit_end_tag = C.GUMBO_INSERTION_IMPLICIT_END_TAG,
    insertion_implied = C.GUMBO_INSERTION_IMPLIED,
    converted_from_end_tag = C.GUMBO_INSERTION_CONVERTED_FROM_END_TAG,
    insertion_from_isindex = C.GUMBO_INSERTION_FROM_ISINDEX,
    insertion_from_image = C.GUMBO_INSERTION_FROM_IMAGE,
    reconstructed_formatting_element = C.GUMBO_INSERTION_RECONSTRUCTED_FORMATTING_ELEMENT,
    adoption_agency_cloned = C.GUMBO_INSERTION_ADOPTION_AGENCY_CLONED,
    adoption_agency_moved = C.GUMBO_INSERTION_ADOPTION_AGENCY_MOVED,
    foster_parented = C.GUMBO_INSERTION_FOSTER_PARENTED
}

setmetatable(typemap, typemap)
setmetatable(quirksmap, quirksmap)

local function get_attributes(attrs)
    if attrs.length ~= 0 then
        local t = {}
        for i = 0, attrs.length - 1 do
            local attr = ffi_cast("GumboAttribute*", attrs.data[i])
            t[i+1] = {
                name = ffi_string(attr.name),
                value = ffi_string(attr.value),
                line = attr.name_start.line,
                column = attr.name_start.column,
                offset = attr.name_start.offset,
                namespace = attrnsmap[tonumber(attr.attr_namespace)]
            }
            t[ffi_string(attr.name)] = ffi_string(attr.value)
        end
        return t
    end
end

local function get_tag_name(element)
    if element.tag == C.GUMBO_TAG_UNKNOWN then
        local original_tag = element.original_tag
        C.gumbo_tag_from_original_text(original_tag)
        return ffi_string(original_tag.data, original_tag.length)
    else
        return ffi_string(C.gumbo_normalized_tagname(element.tag))
    end
end

local function get_parse_flags(parse_flags)
    if parse_flags ~= C.GUMBO_INSERTION_NORMAL then
        parse_flags = tonumber(parse_flags)
        local t = tnew(0, 1)
        for field, flag in pairs(flagsmap) do
            if testflag(parse_flags, flag) then
                t[field] = true
            end
        end
        return t
    end
end

local function create_document(node)
    local document = node.v.document
    local length = document.children.length
    local t = tnew(length, 7)
    t.type = "document"
    t.name = ffi_string(document.name)
    t.public_identifier = ffi_string(document.public_identifier)
    t.system_identifier = ffi_string(document.system_identifier)
    t.has_doctype = document.has_doctype
    t.quirks_mode = quirksmap[tonumber(document.doc_type_quirks_mode)]
    for i = 0, length - 1 do
        t[i+1] = create_node(ffi_cast("GumboNode*", document.children.data[i]))
    end
    return t
end

local function create_element(node)
    local element = node.v.element
    local length = element.children.length
    local t = tnew(length, 7)
    t.type = "element"
    t.tag = get_tag_name(element)
    t.tag_namespace = tagnsmap[tonumber(element.tag_namespace)]
    t.line = element.start_pos.line
    t.column = element.start_pos.column
    t.offset = element.start_pos.offset
    t.parse_flags = get_parse_flags(node.parse_flags)
    t.attr = get_attributes(element.attributes)
    for i = 0, length - 1 do
        t[i+1] = create_node(ffi_cast("GumboNode*", element.children.data[i]))
    end
    return t
end

local function create_text(node)
    local text = node.v.text
    return {
        type = typemap[tonumber(node.type)],
        text = ffi_string(text.text),
        line = text.start_pos.line,
        column = text.start_pos.column,
        offset = text.start_pos.offset
    }
end

create_node = function(node)
    if node.type == C.GUMBO_NODE_ELEMENT then
        return create_element(node)
    else
        return create_text(node)
    end
end

local function parse(input, tab_stop)
    local options = ffi.new("GumboOptions")
    ffi.copy(options, C.kGumboDefaultOptions, ffi.sizeof("GumboOptions"))
    -- The above is for the benefit of luaffi support. LuaJIT allows
    -- using a copy constructor with ffi.new, as in:
    --   local options = ffi.new("GumboOptions", C.kGumboDefaultOptions)
    -- TODO: use the cleaner syntax if/when luaffi supports it

    options.tab_stop = tab_stop or 8
    local output = C.gumbo_parse_with_options(options, input, #input)
    local document = create_document(output.document)
    document.root = document[output.root.index_within_parent + 1]
    C.gumbo_destroy_output(options, output)
    return document
end

return {
    _FFI = true,
    parse = parse
}
