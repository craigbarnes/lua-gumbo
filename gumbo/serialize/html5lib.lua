local util = require "gumbo.serialize.util"

local function attr_iter(attrs, i)
    i = i + 1
    local attr = attrs[i]
    if attr then
        return i, attr.name, attr.value, attr.namespace
    end
end

--- Iterate through attributes in lexicographic order
local function ordered_attrs(attrs)
    -- Create a copy, rather than mutating the original
    local copy = {}
    for i = 1, #attrs do
        local attr = attrs[i]
        copy[i] = {
            name = attr.name,
            value = attr.value,
            namespace = attr.namespace
        }
    end
    table.sort(copy, function(a, b)
        return a.name < b.name
    end)
    return attr_iter, copy, 0
end

return function(node)
    local buf = util.Buffer()
    local indent = util.IndentGenerator(2)
    local level = 0
    local function serialize(node)
        if node.type == "element" then
            local i1 = indent[level]
            if node.tag_namespace ~= "html" then
                buf:appendf('| %s<%s %s>\n', i1, node.tag_namespace, node.tag)
            else
                buf:appendf('| %s<%s>\n', i1, node.tag)
            end
            if node.attr then
                local i2 = indent[level+1]
                for i, name, value, ns in ordered_attrs(node.attr) do
                    if ns then
                        buf:appendf('| %s%s %s="%s"\n', i2, ns, name, value)
                    else
                        buf:appendf('| %s%s="%s"\n', i2, name, value)
                    end
                end
            end
            level = level + 1
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
                    serialize(node[i])
                end
            end
            level = level - 1
        elseif node.type == "text" or node.type == "whitespace" then
            buf:appendf('| %s"%s"\n', indent[level], node.text)
        elseif node.type == "comment" then
            buf:appendf('| %s<!-- %s -->\n', indent[level], node.text)
        elseif node.type == "document" then
            if node.has_doctype == true then
                local pubid = node.public_identifier
                local sysid = node.system_identifier
                if pubid ~= "" or sysid ~= "" then
                    local fmt = '| <!DOCTYPE %s "%s" "%s">\n'
                    buf:appendf(fmt, node.name, pubid, sysid)
                else
                    buf:appendf("| <!DOCTYPE %s>\n", node.name)
                end
            end
            for i = 1, #node do
                serialize(node[i])
            end
        end
    end
    serialize(node)
    return buf:concat()
end
