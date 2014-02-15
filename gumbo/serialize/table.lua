local Buffer = require "gumbo.buffer"
local Indent = require "gumbo.indent"

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

local function to_table(node, buffer, indent_width)
    local buf = buffer or Buffer()
    local indent = Indent(indent_width)

    local function serialize(node, depth, last, index)
        if node.type == "element" then
            local node_length = #node
            local attr_length = #node.attr

            buf:write(indent[depth])
            if index then
                buf:write("[", tostring(index), "] = ")
            end
            buf:write('{\n')
            local i1, i2 = indent[depth+1], indent[depth+2]
            buf:write(i1, 'type = "element",\n')
            buf:write(i1, 'tag = "', node.tag, '",\n')
            buf:write(i1, 'tag_namespace = "', node.tag_namespace, '",\n')
            buf:write(i1, 'line = ', node.line, ',\n')
            buf:write(i1, 'column = ', node.column, ',\n')
            buf:write(i1, 'offset = ', node.offset, ',\n')

            if attr_length > 0 then
                local i3 = indent[depth+3]
                local tmp = Buffer()
                buf:write(i1, 'attr = {\n')
                for i, name, val, ns, line, col, offset in node:attr_iter() do
                    buf:write(i2, escape_key(name), ' = "', escape(val), '",\n')
                    tmp:write(i2, "[", tostring(i), "] = {\n")
                    tmp:write(i3, 'name = "', escape(name), '",\n')
                    tmp:write(i3, 'value = "', escape(val), '",\n')
                    if ns then tmp:write(i3, 'namespace = "', ns, '",\n') end
                    tmp:write(i3, 'line = ', line, ',\n')
                    tmp:write(i3, 'column = ', col, ',\n')
                    tmp:write(i3, 'offset = ', offset, '\n')
                    local sep = (i < attr_length) and "," or ""
                    tmp:write(i2, '}', sep, '\n')
                end
                local sep = (node_length > 0 or node.parse_flags) and "," or ""
                buf:write(tostring(tmp), i1, '}', sep, '\n')
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
                serialize(node[i], depth + 1, i == node_length, i)
            end
            buf:write(indent[depth], '}', last and "" or ",", '\n')
        elseif node.text then
            local i1, i2 = indent[depth], indent[depth+1]
            buf:write(i1)
            if index then
                buf:write("[", tostring(index), "] = ")
            end
            buf:write('{\n')
            buf:write(i2, 'type = "', node.type, '",\n')
            buf:write(i2, 'text = "', escape(node.text), '",\n')
            buf:write(i2, 'line = ', node.line, ',\n')
            buf:write(i2, 'column = ', node.column, ',\n')
            buf:write(i2, 'offset = ', node.offset, '\n')
            buf:write(i1, '}', last and "" or ",", '\n')
        elseif node.type == "document" then
            assert(depth == 0, "document nodes cannot be nested")
            buf:write("{\n")
            local i1 = indent[depth+1]
            buf:write(i1, 'type = "document",\n')
            buf:write(i1, 'has_doctype = ', tostring(node.has_doctype), ',\n')
            buf:write(i1, 'name = "', node.name, '",\n')
            buf:write(i1, 'system_identifier = "', node.system_identifier, '",\n')
            buf:write(i1, 'public_identifier = "', node.public_identifier, '",\n')
            buf:write(i1, 'quirks_mode = "', node.quirks_mode, '",\n')
            local node_length = #node
            for i = 1, node_length do
                serialize(node[i], depth + 1, i == node_length, i)
            end
            buf:write("}\n")
        end
    end
    serialize(node, 0)
    return io.type(buf) and true or tostring(buf)
end

return to_table
