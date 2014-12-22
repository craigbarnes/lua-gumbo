-- This code hasn't been thoroughly tested; do not use yet
-- TODO: Add test cases

local Buffer = require "gumbo.Buffer"
local constants = require "gumbo.constants"
local voidElements = constants.voidElements
local rcdataElements = constants.rcdataElements
local _ENV = nil

local function stripws(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"):gsub("%s+", " "))
end

return function(node, buffer)
    local buf = buffer or Buffer()
    local function serialize(node)
        local type = node.type
        if type == "element" then
            local tag = node.localName
            local insertedByParser = node.insertedByParser
            local implicitEndTag = node.implicitEndTag
            if not insertedByParser then
                buf:write(node.tagHTML)
            end
            if not voidElements[tag] then
                if node:hasChildNodes() then
                    local childNodes = node.childNodes
                    for i = 1, #childNodes do
                        serialize(childNodes[i])
                    end
                end
                if not insertedByParser and not implicitEndTag then
                    buf:write("</", tag, ">")
                end
            end
        elseif type == "text" then
            local parent = node.parentNode
            if parent and rcdataElements[parent.localName] then
                buf:write(node.data)
            else
                buf:write(stripws(node.escapedData))
            end
        elseif type == "document" then
            if node.doctype then
                buf:write("<!DOCTYPE ", node.doctype.name, ">")
            end
            local childNodes = node.childNodes
            for i = 1, #childNodes do
                serialize(childNodes[i])
            end
        end
    end
    serialize(node)
    if buf.tostring then
        return buf:tostring()
    end
end
