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

local typemap = setmetatable({
    [tonumber(C.GUMBO_NODE_DOCUMENT)] = "document",
    [tonumber(C.GUMBO_NODE_ELEMENT)] = "element",
    [tonumber(C.GUMBO_NODE_TEXT)] = "text",
    [tonumber(C.GUMBO_NODE_CDATA)] = "cdata",
    [tonumber(C.GUMBO_NODE_COMMENT)] = "comment",
    [tonumber(C.GUMBO_NODE_WHITESPACE)] = "whitespace"
}, {
    __index = function(self, i)
        error "Error: invalid node type"
    end
})

local quirksmap = setmetatable({
    [tonumber(C.GUMBO_DOCTYPE_NO_QUIRKS)] = "no-quirks",
    [tonumber(C.GUMBO_DOCTYPE_QUIRKS)] = "quirks",
    [tonumber(C.GUMBO_DOCTYPE_LIMITED_QUIRKS)] = "limited-quirks"
}, {
    __index = function(self, i)
        error "Error: invalid quirks mode"
    end
})

local function get_attributes(attrs)
    if attrs.length ~= 0 then
        local t = {}
        for i = 0, attrs.length - 1 do
            local attr = ffi_cast("GumboAttribute*", attrs.data[i])
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

local function create_document(node)
    local document = node.v.document
    local ret = {
        type = "document",
        name = ffi_string(document.name),
        public_identifier = ffi_string(document.public_identifier),
        system_identifier = ffi_string(document.system_identifier),
        has_doctype = document.has_doctype,
        quirks_mode = quirksmap[tonumber(document.doc_type_quirks_mode)]
    }
    for i = 0, document.children.length - 1 do
        ret[i+1] = create_node(ffi_cast("GumboNode*", document.children.data[i]))
    end
    return ret
end

local function create_element(node)
    local element = node.v.element
    local ret = {
        type = "element",
        tag = get_tag_name(element),
        line = element.start_pos.line,
        column = element.start_pos.column,
        offset = element.start_pos.offset,
        parse_flags = tonumber(node.parse_flags),
        attr = get_attributes(element.attributes)
    }
    for i = 0, element.children.length - 1 do
        ret[i+1] = create_node(ffi_cast("GumboNode*", element.children.data[i]))
    end
    return ret
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
    if tonumber(node.type) == tonumber(C.GUMBO_NODE_ELEMENT) then
        return create_element(node)
    else
        return create_text(node)
    end
end

local function parse(input, tab_stop)
    local options = ffi.new("GumboOptions")
    ffi.copy(options, C.kGumboDefaultOptions, ffi.sizeof("GumboOptions"))
    -- The above is for the benefit of LuaFFI support. LuaJIT allows
    -- using a copy constructor with ffi.new, as in:
    --   local options = ffi.new("GumboOptions", C.kGumboDefaultOptions)
    -- TODO: use the cleaner syntax if/when LuaFFI supports it

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
