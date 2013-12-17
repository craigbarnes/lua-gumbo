local util = require "gumbo.serialize.util"

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

local function to_table(node)
    local buf = util.Buffer()
    local indent = util.IndentGenerator()
    local level = 0

    function buf:append_qpair(indent, name, value)
        local escval = value:gsub('[\n\t"]', {
            ["\n"] = "\\n",
            ["\t"] = "\\t",
            ['"'] = '\\"',
        })
        self:appendf('%s%s = "%s",\n', indent, name, escval)
    end

    -- TODO: This code is ugly as sin. Refactor it.
    -- TODO: Use '%q' format specifier instead of manual escaping/append_qpair?
    -- TODO: Refactor attr/parse_flags serialization into a common function?
    local function serialize(node)
        if node.type == "element" then
            buf:appendf("%s{\n", indent[level])
            level = level + 1
            local i1, i2, i3 = indent[level], indent[level+1], indent[level+2]
            buf:append_qpair(i1, "type", "element")
            buf:append_qpair(i1, "tag", node.tag)
            buf:appendf("%s%s = %d,\n", i1, "line", node.line)
            buf:appendf("%s%s = %d,\n", i1, "column", node.column)
            buf:appendf("%s%s = %d,\n", i1, "offset", node.offset)
            if node.attr then -- add attributes
                buf:appendf("%sattr = {\n", i1)
                for i = 1, #node.attr do
                    local a = node.attr[i]
                    -- TODO: wrap table key, e.g. ["xml:v"]
                    buf:append_qpair(i2, a.name, a.value)
                end
                for i = 1, #node.attr do
                    local a = node.attr[i]
                    buf:appendf("%s{\n", i2)
                    buf:append_qpair(i3, "name", a.name)
                    buf:append_qpair(i3, "value", a.value)
                    if a.namespace then
                        buf:append_qpair(i3, "namespace", a.namespace)
                    end
                    buf:appendf("%s%s = %d,\n", i3, "line", a.line)
                    buf:appendf("%s%s = %d,\n", i3, "column", a.column)
                    buf:appendf("%s%s = %d\n", i3, "offset", a.offset)
                    buf:appendf("%s},\n", i2)
                end
                buf:appendf("%s},\n", i1)
            end
            if node.parse_flags then -- add parse flags
                buf:appendf("%sparse_flags = {\n", i1)
                for i = 1, #parse_flags_fields do
                    local field = parse_flags_fields[i]
                    local value = node.parse_flags[field]
                    if value then
                        buf:appendf("%s%s = %s,\n", i2, field, value)
                    end
                end
                buf:appendf("%s},\n", i1)
            end
            for i = 1, #node do -- add children
                serialize(node[i], i)
            end
            level = level - 1
            buf:appendf("%s},\n", indent[level])
        elseif node.text then
            local i1, i2 = indent[level], indent[level+1]
            buf:appendf("%s{\n", i1)
            buf:append_qpair(i2, "type", node.type)
            buf:append_qpair(i2, "text", node.text)
            buf:appendf("%s%s = %d,\n", i2, "line", node.line)
            buf:appendf("%s%s = %d,\n", i2, "column", node.column)
            buf:appendf("%s%s = %d,\n", i2, "offset", node.offset)
            buf:appendf("%s},\n", i1)
        elseif node.type == "document" then
            buf:append("{\n")
            level = level + 1
            local i = indent[level]
            buf:append_qpair(i, "type", "document")
            buf:appendf('%s%s = %s,\n', i, "has_doctype", node.has_doctype)
            buf:append_qpair(i, "name", node.name)
            buf:append_qpair(i, "system_identifier", node.system_identifier)
            buf:append_qpair(i, "public_identifier", node.public_identifier)
            buf:append_qpair(i, "quirks_mode", node.quirks_mode)
            for i = 1, #node do serialize(node[i]) end
            level = level - 1
            buf:append("}\n")
        end
    end

    serialize(node)
    return buf:concat()
end

return to_table
