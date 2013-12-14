#!/usr/bin/env lua

local gumbo = require "gumbo"
local serialize = require "gumbo.serialize.table"
local fmt = string.format

local arg1 = assert(arg[1], "Arg 1 missing")
local arg2 = assert(arg[2], "Arg 2 missing")
local file1 = assert(io.open(arg1))
local file2 = assert(io.open(arg2))
local html = assert(file1:read("*a"))
local ast = assert(file2:read("*a"))
file1:close()
file2:close()
local t1 = assert(gumbo.parse(html))
local f = assert(load(ast, nil, "t"), "Invalid syntax")
local t2 = assert(f())

local text_fields = {
    type = true,
    text = true,
    line = true,
    column = true,
    offset = true
}

local node_fields = {
    text = text_fields,
    comment = text_fields,
    whitespace = text_fields,
    cdata = text_fields,
    document = {
        type = true,
        has_doctype = true,
        name = true,
        system_identifier = true,
        public_identifier = true,
        quirks_mode = true
    },
    element = {
        type = true,
        tag = true,
        line = true,
        column = true,
        offset = true,
--        parse_flags = false
    }
}

local parse_flags_fields = {
    "insertion_by_parser",
    "implicit_end_tag",
    "insertion_implied",
    "converted_from_end_tag",
    "insertion_from_isindex",
    "insertion_from_image",
    "reconstructed_formatting_element",
    "adoption_agency_cloned",
    "adoption_agency_moved",
    "foster_parented"
}

local function compare(node1, node2)
    local type = assert(node1.type)
    local fields = assert(node_fields[type])
    for field, nonnil in pairs(fields) do
        local f1, f2 = node1[field], node2[field]
        assert(f1 ~= nil or nonnil == false)
        assert(f1 == f2, fmt("%s == '%s', expected '%s'", field, f1, f2))
    end
    if type == "element" then
        if node1.parse_flags then
            for i, flag in ipairs(parse_flags_fields) do
                local f1 = node1.parse_flags[flag]
                local f2 = node2.parse_flags[flag]
                assert(f1 == f2, fmt("parse_flags mismatch for: %s", flag))
            end
        end
    end
    if type == "document" or type == "element" then
        -- TODO: compare attribute tables for element nodes
        -- TODO: assert #document >= 2
        local length = #node1
        assert(#node2 == length)
        for i = 1, length do
            compare(node1[i], node2[i])
        end
    end
end

compare(t1, t2)
io.stderr:write(fmt("%s == %s\n", arg1, arg2))
