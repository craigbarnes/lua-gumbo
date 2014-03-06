local util = require "gumbo.util"
local Buffer = util.Buffer
local Indent = util.Indent

local function Set(t)
    local set = {}
    for i = 1, #t do set[t[i]] = true end
    return set
end

local void = Set {
    "area", "base", "basefont", "bgsound", "br", "col", "embed",
    "frame", "hr", "img", "input", "keygen", "link", "menuitem", "meta",
    "param", "source", "track", "wbr"
}

local raw = Set {
    "style", "script", "xmp", "iframe", "noembed", "noframes",
    "plaintext"
}

local boolattr = Set {
    "allowfullscreen", "async", "autofocus", "autoplay", "checked",
    "compact", "controls", "declare", "default", "defer", "disabled",
    "formnovalidate", "hidden", "inert", "ismap", "itemscope", "loop",
    "multiple", "multiple", "muted", "nohref", "noresize", "noshade",
    "novalidate", "nowrap", "open", "readonly", "required", "reversed",
    "scoped", "seamless", "selected", "sortable", "truespeed",
    "typemustmatch"
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
    local get_indent = Indent(indent_width)
    local function serialize(node, depth, parent_tag)
        local indent = get_indent[depth]
        if node.type == "element" then
            local tag = node.tag
            buf:write(indent, "<", tag)
            for index, name, val, ns in node:attr_iter() do
                if ns == "xmlns" and name == "xmlns" then
                    ns = nil
                end
                buf:write(" ", ns and ns..":" or "", name)
                if not boolattr[name] or not (val == "" or val == name) then
                    buf:write('="', escape_attr(val), '"')
                end
            end
            buf:write(">")
            local length = #node
            if void[tag] then
                buf:write("\n")
            elseif length == 0 then
                buf:write("</", tag, ">\n")
            else
                buf:write("\n")
                for i = 1, length do
                    serialize(node[i], depth + 1, node.tag)
                end
                buf:write(indent, "</", tag, ">\n")
            end
        elseif node.type == "text" then
            if raw[parent_tag] then
                buf:write(indent, node.text, "\n")
            else
                buf:write(wrap(escape_text(node.text), indent))
            end
        elseif node.type == "comment" then
            buf:write(indent, "<!--", node.text, "-->\n")
        elseif node.type == "document" then
            if node.has_doctype == true then
                buf:write("<!DOCTYPE ", node.name, ">\n")
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
