-- Replaces all "align" attributes with the CSS "text-align" property.
-- This can be used to filter Pandoc HTML output, which uses the
-- (deprecated) "align" attribute on th and td elements.

local gumbo = require "gumbo"
local document = assert(gumbo.parseFile(arg[1] or io.stdin))

local function fixAlignAttr(elements)
    for i, element in ipairs(elements) do
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
