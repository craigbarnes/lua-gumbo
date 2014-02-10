local Buffer = require "gumbo.buffer"
local Indent = require "gumbo.indent"

return function(node, buffer, indent_width)
    local buf = buffer or Buffer()
    local indent = Indent(indent_width or 2)
    local function serialize(node, level)
        if node.type == "element" then
            local i1, i2 = indent[level], indent[level+1]
            local tagns = (node.tag_namespace == "html") and "" or
                          (node.tag_namespace .. " ")
            buf:write("| ", i1, "<", tagns, node.tag, ">\n")
            table.sort(node.attr, function(a, b) return a.name < b.name end)
            for index, name, value, ns in node:attr_iter() do
                if ns then
                    buf:write("| ", i2, ns, " ", name, '="', value, '"\n')
                else
                    buf:write("| ", i2, name, '="', value, '"\n')
                end
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
                    serialize(node[i], level + 1)
                end
            end
        elseif node.type == "text" or node.type == "whitespace" then
            buf:write("| ", indent[level], '"', node.text, '"\n')
        elseif node.type == "comment" then
            buf:write("| ", indent[level], "<!-- ", node.text, " -->\n")
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
                serialize(node[i], level)
            end
        end
    end
    serialize(node, 0)
    return io.type(buf) and true or tostring(buf)
end
