local Buffer = require "gumbo.buffer"
local Indent = require "gumbo.indent"

return function(node, buffer, indent_width)
    local buf = buffer or Buffer()
    local indent = Indent(indent_width or 2)
    local function serialize(node, depth)
        if node.type == "element" then
            local i1, i2 = indent[depth], indent[depth+1]
            local tagns = (node.tag_namespace == "html") and "" or
                          (node.tag_namespace .. " ")
            buf:write("| ", i1, "<", tagns, node.tag, ">\n")

            -- The html5lib tree format expects attributes to be sorted by
            -- name, in lexicographic order. Instead of sorting in-place or
            -- copying the entire table, we build a lightweight, sorted index.
            local attr = node.attr
            local attr_length = #attr
            local attr_index = {}
            for i = 1, attr_length do
                attr_index[i] = i
            end
            table.sort(attr_index, function(a, b)
                return attr[a].name < attr[b].name
            end)
            for i = 1, attr_length do
                local a = attr[attr_index[i]]
                local ns = a.namespace and (a.namespace .. " ") or ""
                buf:write("| ", i2, ns, a.name, '="', a.value, '"\n')
            end

            for i = 1, #node do
                if node[i].type == "text" and node[i+1]
                   and node[i+1].type == "text"
                then
                    -- Merge adjacent text nodes, as expected by the
                    -- spec and the html5lib tests
                    -- TODO: Why doesn't Gumbo do this during parsing?
                    local text = node[i+1].text
                    node[i+1] = node[i]
                    node[i+1].text = node[i+1].text .. text
                else
                    serialize(node[i], depth + 1)
                end
            end
        elseif node.type == "text" or node.type == "whitespace" then
            buf:write("| ", indent[depth], '"', node.text, '"\n')
        elseif node.type == "comment" then
            buf:write("| ", indent[depth], "<!-- ", node.text, " -->\n")
        elseif node.type == "document" then
            if node.has_doctype == true then
                buf:write("| <!DOCTYPE ", node.name)
                local pub, sys = node.public_identifier, node.system_identifier
                if pub ~= "" or sys ~= "" then
                    buf:write(' "', pub, '" "', sys, '"')
                end
                buf:write(">\n")
            end
            for i = 1, #node do
                serialize(node[i], depth)
            end
        end
    end
    serialize(node, 0)
    return io.type(buf) and true or tostring(buf)
end
