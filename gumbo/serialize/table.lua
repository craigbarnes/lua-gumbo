local util = require "gumbo.util"
local Buffer = util.Buffer
local Indent = util.Indent

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

local function to_table(node, buffer, indent_width)
    local buf = buffer or Buffer()
    local indent = Indent(indent_width)

    local function serialize(node, depth, index, is_last_child)
        if node.type == "element" then
            local node_length = #node
            local attr_length = #node.attributes
            local i1, i2 = indent[depth+1], indent[depth+2]
            buf:write(indent[depth])
            if index then
                buf:write("[", tostring(index), "] = ")
            end
            buf:write(
                "{\n",
                i1, 'type = "element",\n',
                i1, 'localName = "', node.localName, '",\n'
            )
            if node.namespace then
                buf:write(i1, 'namespace = "', node.namespace, '",\n')
            end
            buf:write(
                i1, 'line = ', node.line, ',\n',
                i1, 'column = ', node.column, ',\n',
                i1, 'offset = ', node.offset, ',\n'
            )
            if attr_length > 0 then
                local i3 = indent[depth+3]
                buf:write(i1, 'attributes = {\n')
                for i, name, val, pfx, line, col, offset in node:attr_iter() do
                    buf:write(
                        i2, "[", tostring(i), "] = {\n",
                        i3, 'name = "', escape(name), '",\n',
                        i3, 'value = "', escape(val), '",\n'
                    )
                    if pfx then
                        buf:write(i3, 'prefix = "', pfx, '",\n')
                    end
                    buf:write(
                        i3, 'line = ', line, ',\n',
                        i3, 'column = ', col, ',\n',
                        i3, 'offset = ', offset, '\n',
                        i2, i == attr_length and '}\n' or '},\n'
                    )
                end
                local sep = (node_length > 0 or node.parse_flags) and "," or ""
                buf:write(i1, '}', sep, '\n')
            end

            if node.parse_flags then
                buf:write(i1, 'parse_flags = {\n')
                for i = 1, #parse_flags_fields do
                    local field = parse_flags_fields[i]
                    local value = node.parse_flags[field]
                    if value then
                        buf:write(i2, field, " = ", tostring(value), ",\n")
                    end
                end
                buf:write(i1, '}', node_length > 0 and "," or "", '\n')
            end
            for i = 1, node_length do
                serialize(node[i], depth + 1, i, i == node_length)
            end
            buf:write(indent[depth], '}', is_last_child and "" or ",", '\n')
        elseif node.data then
            local i1, i2 = indent[depth], indent[depth+1]
            buf:write(i1)
            if index then
                buf:write("[", tostring(index), "] = ")
            end
            buf:write(
                "{\n",
                i2, 'type = "', node.type, '",\n',
                i2, 'data = "', escape(node.data), '",\n',
                i2, 'line = ', node.line, ',\n',
                i2, 'column = ', node.column, ',\n',
                i2, 'offset = ', node.offset, '\n',
                i1, '}', is_last_child and "" or ",", '\n'
            )
        elseif node.type == "document" then
            assert(depth == 0, "document nodes cannot be nested")
            local i1, i2 = indent[depth+1], indent[depth+2]
            local doctype = node.doctype
            buf:write(
                "{\n",
                i1, 'type = "document",\n',
                i1, 'quirks_mode = "', node.quirks_mode, '",\n'
            )
            if doctype then
                buf:write(
                    i1, 'doctype = {\n',
                    i2, 'name = "', doctype.name, '",\n',
                    i2, 'systemId = "', doctype.systemId, '",\n',
                    i2, 'publicId = "', doctype.publicId, '"\n',
                    i1, '},\n'
                )
            end
            for i = 1, #node do
                serialize(node[i], depth + 1, i, i == #node)
            end
            buf:write("}\n")
        end
    end
    serialize(node, 0)
    return io.type(buf) and true or tostring(buf)
end

return to_table
