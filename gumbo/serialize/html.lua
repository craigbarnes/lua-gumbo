local util = require "gumbo.serialize.util"
local Rope = util.Rope
local indent = util.indent
local wrap = util.wrap

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

local entity_map = {
    ["&"] = "&amp;",
    ["<"] = "&lt;",
    [">"] = "&gt;",
    ['"'] = "&quot;",
    ["'"] = "&#x27;",
    ["/"] = "&#x2F;"
}

local function escape(s)
    return string.gsub(s, "[&<>\"'/]", entity_map)
end

local function to_html(node)
    local rope = Rope()
    local level = 0

    local function serialize(node)
        if node.type == "element" then
            local length = #node
            -- Add start tag and attributes
            rope:appendf('%s<%s', indent[level], node.tag)
            for name, value in pairs(node.attr or {}) do
                rope:appendf(' %s="%s"', name, value:gsub('"', "&quot;"))
            end

            if length > 0 then -- recurse into child nodes
                rope:append(">\n")
                level = level + 1
                for i = 1, length do
                    serialize(node[i])
                end
                level = level - 1
                if not void[node.tag] then
                    rope:appendf("%s</%s>\n", indent[level], node.tag)
                end
            else
                rope:append(">")
                if not void[node.tag] then
                    rope:appendf("</%s>\n", node.tag)
                else
                    rope:append("\n")
                end
            end
        elseif node.type == "text" then
            rope:append(wrap(escape(node.text), indent[level]))
        elseif node.type == "comment" then
            rope:appendf('%s<!--%s-->\n', indent[level], node.text)
        elseif node.type == "document" then
            if node.has_doctype == true then
                rope:appendf("<!doctype %s>\n", node.name)
            end
            for i = 1, #node do
                serialize(node[i])
            end
        end
    end

    serialize(node)
    return rope:concat()
end

return to_html
