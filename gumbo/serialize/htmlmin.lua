-- This code hasn't been thoroughly tested; do not use yet
-- TODO: Add test cases

local Buffer = require "gumbo.Buffer"
local Set = require "gumbo.Set"
local util = require "gumbo.util"
local constants = require "gumbo.constants"
local voidElements = constants.voidElements
local rcdataElements = constants.rcdataElements
local trimAndCollapseWhitespace = util.trimAndCollapseWhitespace
local _ENV = nil

-- These elements are "display: inline" by default
-- (https://developer.mozilla.org/en-US/docs/Web/HTML/Inline_elements#elements)
local inlineElements = Set [[
    a abbr acronym audio b bdi bdo big br button canvas cite code data
    datalist del dfn em embed i iframe img input ins kbd label map mark
    meter noscript object output picture progress q ruby s samp script
    select slot small span strong sub sup svg template textarea time tt
    u var video wbr
]]

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
                buf:write(trimAndCollapseWhitespace(node.escapedData))
            end
        elseif type == "whitespace" then
            local parent = node.parentNode
            if parent and inlineElements[parent.localName] then
                buf:write(" ")
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
