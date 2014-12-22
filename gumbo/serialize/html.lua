local Buffer = require "gumbo.Buffer"
local Indent = require "gumbo.serialize.Indent"
local constants = require "gumbo.constants"
local voidElements = constants.voidElements
local rcdataElements = constants.rcdataElements
local _ENV = nil

local function wrap(text, indent)
    local limit = 78
    local indentWidth = #indent
    local pos = 1 - indentWidth
    text = text:gsub("^%s*(.-)%s*$", "%1")
    local function reflow(start, word, stop)
        if stop - pos > limit then
            pos = start - indentWidth
            return "\n" .. indent .. word
        else
            return " " .. word
        end
    end
    return indent, text:gsub("%s+()(%S+)()", reflow), "\n"
end

return function(node, buffer, indentWidth)
    local buf = buffer or Buffer()
    local getIndent = Indent(indentWidth)
    local function serialize(node, depth)
        local type = node.type
        local indent = getIndent[depth]
        if type == "element" then
            local tag = node.localName
            buf:write(indent, node.tagHTML)
            local children = node.childNodes
            local length = #children
            if voidElements[tag] then
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
            if parent and rcdataElements[parent.localName] then
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
    if buf.tostring then
        return buf:tostring()
    end
end
