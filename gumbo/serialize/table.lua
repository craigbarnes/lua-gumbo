local util = require "gumbo.serialize.util"
local Rope = util.Rope
local indent = util.indent

local function to_table(node)
    local rope = Rope()
    local level = 0

    function rope:append_qpair(indent, name, value)
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
            rope:appendf("%s{\n", indent[level])
            level = level + 1
            local i1 = indent[level]
            local i2 = indent[level+1]
            rope:append_qpair(i1, "type", "element")
            rope:append_qpair(i1, "tag", node.tag)
            rope:appendf("%s%s = %d,\n", i1, "line", node.line)
            rope:appendf("%s%s = %d,\n", i1, "column", node.column)
            rope:appendf("%s%s = %d,\n", i1, "offset", node.offset)
            if node.attr then -- add attributes
                rope:appendf("%sattr = {\n", i1)
                for name, value in pairs(node.attr) do
                    rope:append_qpair(i2, name, value)
                end
                rope:appendf("%s},\n", i1)
            end
            if node.parse_flags then -- add parse flags
                rope:appendf("%sparse_flags = {\n", i1)
                for name, value in pairs(node.parse_flags) do
                    rope:appendf("%s%s = %s,\n", i2, name, value)
                end
                rope:appendf("%s},\n", i1)
            end
            for i = 1, #node do -- add children
                serialize(node[i], i)
            end
            level = level - 1
            rope:appendf("%s},\n", indent[level])
        elseif node.text then
            local i1, i2 = indent[level], indent[level+1]
            rope:appendf("%s{\n", i1)
            rope:append_qpair(i2, "type", node.type)
            rope:append_qpair(i2, "text", node.text)
            rope:appendf("%s%s = %d,\n", i2, "line", node.line)
            rope:appendf("%s%s = %d,\n", i2, "column", node.column)
            rope:appendf("%s%s = %d,\n", i2, "offset", node.offset)
            rope:appendf("%s},\n", i1)
        elseif node.type == "document" then
            rope:append("{\n")
            level = level + 1
            local i = indent[level]
            rope:append_qpair(i, "type", "document")
            rope:appendf('%s%s = %s,\n', i, "has_doctype", node.has_doctype)
            rope:append_qpair(i, "name", node.name)
            rope:append_qpair(i, "system_identifier", node.system_identifier)
            rope:append_qpair(i, "public_identifier", node.public_identifier)
            rope:append_qpair(i, "quirks_mode", node.quirks_mode)
            for i = 1, #node do serialize(node[i]) end
            level = level - 1
            rope:append("}\n")
        end
    end

    serialize(node)
    return rope:concat()
end

return to_table
