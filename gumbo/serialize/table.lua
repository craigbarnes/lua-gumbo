local Buffer = require "gumbo.util.buffer"
local Indent = require "gumbo.util.indent"

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

local function to_table(node)
    local buf = Buffer()
    local indent = Indent()
    local level = 0
    local sfmt = '%s%s = "%s",\n'
    local nfmt = "%s%s = %d,\n"
    local bfmt = '%s%s = %s,\n'

    -- TODO: omit trailing commas where not required
    local function serialize(node)
        if node.type == "element" then
            buf:appendf("%s{\n", indent[level])
            local i1, i2 = indent[level+1], indent[level+2]
            buf:appendf(sfmt, i1, "type", "element")
            buf:appendf(sfmt, i1, "tag", node.tag)
            buf:appendf(sfmt, i1, "tag_namespace", node.tag_namespace)
            buf:appendf(nfmt, i1, "line", node.line)
            buf:appendf(nfmt, i1, "column", node.column)
            buf:appendf(nfmt, i1, "offset", node.offset)

            if node.attr.length > 0 then
                local i3 = indent[level+3]
                local tmp = Buffer()
                buf:appendf("%sattr = {\n", i1)
                for i, name, val, ns, line, col, offset in node.attr:iter() do
                    buf:appendf(sfmt, i2, escape_key(name), escape(val))
                    tmp:appendf("%s{\n", i2)
                    tmp:appendf(sfmt, i3, "name", escape(name))
                    tmp:appendf(sfmt, i3, "value", escape(val))
                    tmp:appendf(ns and sfmt or bfmt, i3, "namespace", ns)
                    tmp:appendf(nfmt, i3, "line", line)
                    tmp:appendf(nfmt, i3, "column", col)
                    tmp:appendf("%s%s = %d\n", i3, "offset", offset)
                    tmp:appendf("%s},\n", i2)
                end
                buf:append(tmp:concat())
                buf:appendf("%s},\n", i1)
            end

            if node.parse_flags then
                buf:appendf("%sparse_flags = {\n", i1)
                for i = 1, #parse_flags_fields do
                    local field = parse_flags_fields[i]
                    local value = node.parse_flags[field]
                    if value then
                        buf:appendf(bfmt, i2, field, value)
                    end
                end
                buf:appendf("%s},\n", i1)
            end
            level = level + 1
            for i = 1, #node do
                serialize(node[i], i)
            end
            level = level - 1
            buf:appendf("%s},\n", indent[level])
        elseif node.text then
            local i1, i2 = indent[level], indent[level+1]
            buf:appendf("%s{\n", i1)
            buf:appendf(sfmt, i2, "type", node.type)
            buf:appendf(sfmt, i2, "text", escape(node.text))
            buf:appendf(nfmt, i2, "line", node.line)
            buf:appendf(nfmt, i2, "column", node.column)
            buf:appendf(nfmt, i2, "offset", node.offset)
            buf:appendf("%s},\n", i1)
        elseif node.type == "document" then
            assert(level == 0, "document nodes cannot be nested")
            buf:append("{\n")
            local i1 = indent[level+1]
            buf:appendf(sfmt, i1, "type", "document")
            buf:appendf(bfmt, i1, "has_doctype", node.has_doctype)
            buf:appendf(sfmt, i1, "name", node.name)
            buf:appendf(sfmt, i1, "system_identifier", node.system_identifier)
            buf:appendf(sfmt, i1, "public_identifier", node.public_identifier)
            buf:appendf(sfmt, i1, "quirks_mode", node.quirks_mode)
            level = level + 1
            for i = 1, #node do
                serialize(node[i])
            end
            level = level - 1
            buf:append("}\n")
        end
    end
    serialize(node)
    return buf:concat()
end

return to_table
