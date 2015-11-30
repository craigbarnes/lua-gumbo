-- Pandoc uses the obsolete "align" attribute on th and td elements.
-- This example replaces all such occurrences with the CSS text-align property.
local gumbo = require "gumbo"
local document = assert(gumbo.parseFile(arg[1] or io.stdin))

local function fixAlignAttr(elements)
    for i = 1, elements.length do
        local element = elements[i]
        local align = element:getAttribute("align")
        if align then
            if align ~= "left" then -- left is the default for ltr languages
                local css = "text-align:" .. align
                local style = element:getAttribute("style")
                if style then
                    css = style .. "; " .. css
                end
                element:setAttribute("style", css)
            end
            element:removeAttribute("align")
        end
    end
end

fixAlignAttr(document:getElementsByTagName("td"))
fixAlignAttr(document:getElementsByTagName("th"))

document:serialize(io.stdout)
