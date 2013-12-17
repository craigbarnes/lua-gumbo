local util = require "gumbo.serialize.util"

-- Set of void elements
-- whatwg.org/specs/web-apps/current-work/multipage/syntax.html#void-elements
local void = {
    area = true,
    base = true,
    br = true,
    col = true,
    embed = true,
    hr = true,
    img = true,
    input = true,
    keygen = true,
    link = true,
    menuitem = true,
    meta = true,
    param = true,
    source = true,
    track = true,
    wbr = true
}

local function escape(s)
    return s:gsub("[&<>\"'/]", {
        ["&"] = "&amp;",
        ["<"] = "&lt;",
        [">"] = "&gt;",
        ['"'] = "&quot;",
        ["'"] = "&#x27;",
        ["/"] = "&#x2F;"
    })
end

local function to_html(node)
    local buf = util.Buffer()
    local indent = util.IndentGenerator()
    local wrap = util.wrap
    local level = 0

    local function serialize(node)
        if node.type == "element" then
            buf:appendf('%s<%s', indent[level], node.tag)
            local attributes = node.attr
            if attributes then
                for i = 1, #attributes do
                    local attr = attributes[i]
                    local escaped_value = attr.value:gsub("'", "&quot;")
                    buf:appendf(' %s="%s"', attr.name, escaped_value)
                end
            end

            local length = #node
            if length > 0 then -- recurse into child nodes
                buf:append(">\n")
                level = level + 1
                for i = 1, length do
                    serialize(node[i])
                end
                level = level - 1
                if not void[node.tag] then
                    buf:appendf("%s</%s>\n", indent[level], node.tag)
                end
            else
                buf:append(">")
                if not void[node.tag] then
                    buf:appendf("</%s>\n", node.tag)
                else
                    buf:append("\n")
                end
            end
        elseif node.type == "text" then
            buf:append(wrap(escape(node.text), indent[level]))
        elseif node.type == "comment" then
            buf:appendf('%s<!--%s-->\n', indent[level], node.text)
        elseif node.type == "document" then
            if node.has_doctype == true then
                buf:appendf("<!doctype %s>\n", node.name)
            end
            for i = 1, #node do
                serialize(node[i])
            end
        end
    end

    serialize(node)
    return buf:concat()
end

return to_html
