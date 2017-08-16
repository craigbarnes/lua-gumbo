-- Replaces all "align" attributes on td/th elements with a "style"
-- attribute containing the equivalent CSS "text-align" property.
-- This can be used to fix Pandoc HTML output.

local gumbo = require "gumbo"
local Set = require "gumbo.Set"
local document = assert(gumbo.parseFile(arg[1] or io.stdin))
local alignments = Set{"left", "right", "center", "start", "end"}

local function fixAlignAttr(element)
    local align = element:getAttribute("align")
    if align and alignments[align] then
        local style = element:getAttribute("style")
        if style then
            element:setAttribute("style", style .. "; text-align:" .. align)
        else
            element:setAttribute("style", "text-align:" .. align)
        end
        element:removeAttribute("align")
    end
end

for node in document.body:walk() do
    if node.localName == "td" or node.localName == "th" then
        fixAlignAttr(node)
    end
end

document:serialize(io.stdout)
