local Buffer = require "gumbo.Buffer"
local Indent = require "gumbo.serialize.Indent"
local ipairs = ipairs
local _ENV = nil

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
        local type = node.type
        local indent = get_indent[depth]
        if type == "element" then
            local tag = node.localName
            buf:write(indent, node.tagHTML)
            local children = node.childNodes
            local length = #children
            if node.isVoid then
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
        elseif type == "text" then
            local parent = node.parentNode
            if parent and parent.isRaw then
                buf:write(indent, node.data, "\n")
            else
                buf:write(wrap(node.escapedData, indent))
            end
        elseif type == "comment" then
            buf:write(indent, "<!--", node.data, "-->\n")
        elseif type == "document" then
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
    if buf ~= buffer then
        return buf:tostring()
    end
end

return to_html
