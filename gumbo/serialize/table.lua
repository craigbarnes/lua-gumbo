local Buffer = require "gumbo.Buffer"
local Indent = require "gumbo.serialize.Indent"
local format = string.format

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
            local children = node.childNodes
            local node_length = #children
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
            if node.namespaceURI ~= "http://www.w3.org/1999/xhtml" then
                buf:write(i1, 'namespaceURI = "', node.namespaceURI, '",\n')
            end
            if node.parseFlags then
                local flags = format("0x%x", node.parseFlags)
                buf:write(i1, 'parseFlags = ', flags, ',\n')
            end
            buf:write(
                i1, 'line = ', node.line, ',\n',
                i1, 'column = ', node.column, ',\n',
                i1, 'offset = ', node.offset, ',\n'
            )
            if attr_length > 0 then
                local i3 = indent[depth+3]
                buf:write(i1, 'attributes = {\n')
                for i, attr in ipairs(node.attributes) do
                    buf:write(
                        i2, "[", tostring(i), "] = {\n",
                        i3, 'name = "', escape(attr.name), '",\n',
                        i3, 'value = "', escape(attr.value), '",\n'
                    )
                    if attr.prefix then
                        buf:write(i3, 'prefix = "', attr.prefix, '",\n')
                    end
                    buf:write(
                        i3, 'line = ', attr.line, ',\n',
                        i3, 'column = ', attr.column, ',\n',
                        i3, 'offset = ', attr.offset, '\n',
                        i2, i == attr_length and '}\n' or '},\n'
                    )
                end
                buf:write(i1, '}', node_length > 0 and "," or "", '\n')
            end
            for i = 1, node_length do
                serialize(children[i], depth + 1, i, i == node_length)
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
                i1, 'quirksMode = "', node.quirksMode, '",\n'
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
            local children = node.childNodes
            local n = #children
            for i = 1, n do
                serialize(children[i], depth + 1, i, i == n)
            end
            buf:write("}\n")
        end
    end
    serialize(node, 0)
    return io.type(buf) and true or tostring(buf)
end

return to_table
