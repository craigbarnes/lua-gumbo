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
            table.sort(node.attr, function(a, b) return a.name < b.name end)
            for _, n, v, ns in node:attr_iter() do
                buf:write("| ", i2, ns and ns.." " or "", n, '="', v, '"\n')
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
