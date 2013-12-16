local util = require "gumbo.serialize.util"
local Rope = util.Rope

return function(node)
    local rope = Rope()
    local indent = "  "
    local level = 0
    local function serialize(node)
        if node.type == "element" then
            local length = #node
            rope:appendf('| %s<%s>\n', indent:rep(level), node.tag)
            for name, value in pairs(node.attr or {}) do
                rope:appendf('| %s%s="%s"\n', indent:rep(level+1), name, value)
            end
            level = level + 1
            for i = 1, length do
                serialize(node[i])
            end
            level = level - 1
        elseif node.type == "text" then
            rope:appendf('| %s"%s"\n', indent:rep(level), node.text)
        elseif node.type == "comment" then
            rope:appendf('| %s<!--%s-->\n', indent:rep(level), node.text)
        elseif node.type == "document" then
            serialize(node.root)
        end
    end
    serialize(node)
    return rope:concat()
end
