local Buffer = require "gumbo.buffer"
local Indent = require "gumbo.indent"

-- TODO:
-- * Conform to the spec for HTML fragment serialization:
--  * Include attribute namespace prefixes

-- Set of void elements
-- whatwg.org/specs/web-apps/current-work/multipage/syntax.html#void-elements
local void = {
    area = true,
    base = true,
    basefont = true,
    bgsound = true,
    br = true,
    col = true,
    embed = true,
    frame = true,
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

-- Escaping a string consists of running the following steps:
-- 1. Replace any occurrence of the "&" character by the string "&amp;".
-- 2. Replace any occurrences of the U+00A0 NO-BREAK SPACE character by the
--    string "&nbsp;".
-- 3. If the algorithm was invoked in the attribute mode, replace any
--    occurrences of the """ character by the string "&quot;".
-- 4. If the algorithm was not invoked in the attribute mode, replace any
--    occurrences of the "<" character by the string "&lt;", and any
--    occurrences of the ">" character by the string "&gt;".

local escmap = {
    ["&"] = "&amp;",
    ["<"] = "&lt;",
    [">"] = "&gt;",
    ['"'] = "&quot;"
}

local function escape_text(text)
    return (text:gsub("[&<>]", escmap):gsub("\xC2\xA0", "&nbsp;"))
end

local function escape_attr(text)
    return (text:gsub('[&"]', escmap):gsub("\xC2\xA0", "&nbsp;"))
end

local function wrap(text, indent)
    local limit = 78
    local indent_width = #indent
    local pos = 1 - indent_width
    local function reflow(start, word, stop)
        if stop - pos > limit then
            pos = start - indent_width
            return "\n" .. indent .. word
        else
            return " " .. word
        end
    end
    return indent, text:gsub("%s+()(%S+)()", reflow), "\n"
end

local function to_html(node, buffer, indent_width)
    local buf = buffer or Buffer()
    local indent = Indent(indent_width)
    local function serialize(node, depth)
        if node.type == "element" then
            local tag = node.tag
            buf:write(indent[depth], "<", tag)
            for index, name, value in node:attr_iter() do
                if value == "" then
                    buf:write(" ", name)
                else
                    buf:write(" ", name, '="', escape_attr(value), '"')
                end
            end
            buf:write(">")
            local length = #node
            if length == 0 then
                if not void[tag] then
                    buf:write("</", tag, ">")
                end
            elseif tag == "script" or tag == "style" then -- Raw text node
                assert(length == 1 and node[1].type == "text")
                buf:write("\n")
                buf:write(wrap(node[1].text, indent[depth+1]))
                buf:write(indent[depth], "</", tag, ">")
            elseif length == 1 and node[1].type == "text"
                   and #node.attr == 0 and #node[1].text <= 40
            then
                buf:write(escape_text(node[1].text))
                buf:write("</", tag, ">")
            else
                buf:write("\n")
                for i = 1, length do
                    serialize(node[i], depth + 1)
                end
                buf:write(indent[depth], "</", tag, ">")
            end
            buf:write("\n")
        elseif node.type == "text" then
            buf:write(wrap(escape_text(node.text), indent[depth]))
        elseif node.type == "comment" then
            buf:write(indent[depth], "<!--", node.text, "-->\n")
        elseif node.type == "document" then
            if node.has_doctype == true then
                buf:write("<!doctype ", node.name, ">\n")
            end
            for i = 1, #node do
                serialize(node[i], depth)
            end
        end
    end
    serialize(node, 0)
    return io.type(buf) and true or tostring(buf)
end

return to_html
