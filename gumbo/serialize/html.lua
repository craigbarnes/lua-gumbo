local util = require "gumbo.serialize.util"

-- This has had much less attention than the other two serializers and is
-- inherently much harder to do properly. Consider it experimental for now.

-- TODO:
-- * Collapse newlines around inline elements and short block elements.
-- * Handle <style>, <script> and <pre> elements properly.
-- * Implement a "minified" mode.
-- * Implement escaping for special characters in tag names (e.g. '=')?

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

local escmap = {
    ["&"] = "&amp;",
    ["<"] = "&lt;",
    [">"] = "&gt;"
}

local function escape(text)
    return text:gsub("[&<>]", escmap)
end

local function wrap(text, indent)
    local limit = 78
    local indent_width = #indent
    local pos = 1 - indent_width
    local str = text:gsub("(%s+)()(%S+)()", function(_, start, word, stop)
        if stop - pos > limit then
            pos = start - indent_width
            return "\n" .. indent .. word
        else
            return " " .. word
        end
    end)
    return indent .. str .. "\n"
end

local function to_html(node)
    local buf = util.Buffer()
    local indent = util.IndentGenerator()
    local level = 0

    local function serialize(node)
        if node.type == "element" then
            buf:appendf('%s<%s', indent[level], node.tag)
            local attributes = node.attr
            if attributes then
                for i = 1, #attributes do
                    local attr = attributes[i]
                    if attr.value == "" then
                        buf:appendf(' %s', attr.name)
                    else
                        local escaped_value = attr.value:gsub('"', "&quot;")
                        buf:appendf(' %s="%s"', attr.name, escaped_value)
                    end
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
