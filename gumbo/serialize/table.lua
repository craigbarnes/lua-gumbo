local Buffer = require "gumbo.buffer"
local Indent = require "gumbo.indent"
local fmt = string.format

local parse_flags_fields = {
    -- Serialized in this order:
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

local escmap = {
    ["\n"] = "\\n",
    ["\t"] = "\\t",
    ['"'] = '\\"'
}

local function escape(text)
    return text:gsub('[\n\t"]', escmap)
end

local function escape_key(key)
    if key:match("^[A-Za-z_][A-Za-z0-9_]*$") then
        return key
    else
        return string.format('["%s"]', escape(key))
    end
end

local function to_table(node, buffer)
    local buf = buffer or Buffer()
    local indent = Indent()
    local level = 0
    local sfmt = '%s%s = "%s",\n'
    local nfmt = "%s%s = %d,\n"
    local bfmt = '%s%s = %s,\n'

    -- TODO: omit trailing commas where not required
    local function serialize(node)
        if node.type == "element" then
            buf:write(fmt("%s{\n", indent[level]))
            local i1, i2 = indent[level+1], indent[level+2]
            buf:write(fmt(sfmt, i1, "type", "element"))
            buf:write(fmt(sfmt, i1, "tag", node.tag))
            buf:write(fmt(sfmt, i1, "tag_namespace", node.tag_namespace))
            buf:write(fmt(nfmt, i1, "line", node.line))
            buf:write(fmt(nfmt, i1, "column", node.column))
            buf:write(fmt(nfmt, i1, "offset", node.offset))

            if node.attr.length > 0 then
                local i3 = indent[level+3]
                local tmp = Buffer()
                buf:write(fmt("%sattr = {\n", i1))
                for i, name, val, ns, line, col, offset in node.attr:iter() do
                    buf:write(fmt(sfmt, i2, escape_key(name), escape(val)))
                    tmp:write(fmt("%s{\n", i2))
                    tmp:write(fmt(sfmt, i3, "name", escape(name)))
                    tmp:write(fmt(sfmt, i3, "value", escape(val)))
                    tmp:write(fmt(ns and sfmt or bfmt, i3, "namespace", ns))
                    tmp:write(fmt(nfmt, i3, "line", line))
                    tmp:write(fmt(nfmt, i3, "column", col))
                    tmp:write(fmt("%s%s = %d\n", i3, "offset", offset))
                    tmp:write(fmt("%s},\n", i2))
                end
                buf:write(tostring(tmp))
                buf:write(fmt("%s},\n", i1))
            end

            if node.parse_flags then
                buf:write(fmt("%sparse_flags = {\n", i1))
                for i = 1, #parse_flags_fields do
                    local field = parse_flags_fields[i]
                    local value = node.parse_flags[field]
                    if value then
                        buf:write(fmt(bfmt, i2, field, value))
                    end
                end
                buf:write(fmt("%s},\n", i1))
            end
            level = level + 1
            for i = 1, #node do
                serialize(node[i], i)
            end
            level = level - 1
            buf:write(fmt("%s},\n", indent[level]))
        elseif node.text then
            local i1, i2 = indent[level], indent[level+1]
            buf:write(fmt("%s{\n", i1))
            buf:write(fmt(sfmt, i2, "type", node.type))
            buf:write(fmt(sfmt, i2, "text", escape(node.text)))
            buf:write(fmt(nfmt, i2, "line", node.line))
            buf:write(fmt(nfmt, i2, "column", node.column))
            buf:write(fmt(nfmt, i2, "offset", node.offset))
            buf:write(fmt("%s},\n", i1))
        elseif node.type == "document" then
            assert(level == 0, "document nodes cannot be nested")
            buf:write("{\n")
            local i1 = indent[level+1]
            buf:write(fmt(sfmt, i1, "type", "document"))
            buf:write(fmt(bfmt, i1, "has_doctype", node.has_doctype))
            buf:write(fmt(sfmt, i1, "name", node.name))
            buf:write(fmt(sfmt, i1, "system_identifier", node.system_identifier))
            buf:write(fmt(sfmt, i1, "public_identifier", node.public_identifier))
            buf:write(fmt(sfmt, i1, "quirks_mode", node.quirks_mode))
            level = level + 1
            for i = 1, #node do
                serialize(node[i])
            end
            level = level - 1
            buf:write("}\n")
        end
    end
    serialize(node)
    return tostring(buf)
end

return to_table
