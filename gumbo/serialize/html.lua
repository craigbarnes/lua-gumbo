local Buffer = require "gumbo.Buffer"
local Set = require "gumbo.Set"
local Indent = require "gumbo.serialize.Indent"
local ipairs, iotype, tostring = ipairs, io.type, tostring
local _ENV = nil

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

local function wrap(text, indent)
    local limit = 78
    local indent_width = #indent
    local pos = 1 - indent_width
    text = text:gsub("^%s*(.-)%s*$", "%1")
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
    local function serialize(node, depth)
        local indent = get_indent[depth]
        if node.type == "element" then
            local tag = node.localName
            buf:write(indent, "<", tag)
            for i, attr in ipairs(node.attributes) do
                local ns, name, val = attr.prefix, attr.name, attr.value
                if ns and not (ns == "xmlns" and name == "xmlns") then
                    buf:write(" ", ns, ":", name)
                else
                    buf:write(" ", name)
                end
                if not boolattr[name] or not (val == "" or val == name) then
                    buf:write('="', attr.escapedValue, '"')
                end
            end
            buf:write(">")
            local children = node.childNodes
            local length = #children
            if void[tag] then
                buf:write("\n")
            elseif length == 0 then
                buf:write("</", tag, ">\n")
            else
                buf:write("\n")
                for i = 1, length do
                    serialize(children[i], depth + 1)
                end
                buf:write(indent, "</", tag, ">\n")
            end
        elseif node.type == "text" then
            local parent = node.parentNode
            if parent and raw[parent.localName] then
                buf:write(indent, node.data, "\n")
            else
                buf:write(wrap(node.escapedData, indent))
            end
        elseif node.type == "comment" then
            buf:write(indent, "<!--", node.data, "-->\n")
        elseif node.type == "document" then
            if node.doctype then
                buf:write("<!DOCTYPE ", node.doctype.name, ">\n")
            end
            local children = node.childNodes
            for i = 1, #children do
                serialize(children[i], depth)
            end
        end
    end
    serialize(node, 0)
    return iotype(buf) and true or tostring(buf)
end

return to_html
