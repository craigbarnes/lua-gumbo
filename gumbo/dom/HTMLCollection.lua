local assertions = require "gumbo.dom.assertions"
local assertString = assertions.assertString
local type, ipairs = type, ipairs
local _ENV = nil
local HTMLCollection = {}

function HTMLCollection:__index(k)
    local field = HTMLCollection[k]
    if field then
        return field
    elseif type(k) == "string" then
        return self:namedItem(k)
    end
end

function HTMLCollection:item(index)
    return self[index]
end

function HTMLCollection:namedItem(name)
    assertString(name)
    if name ~= "" then
        for i, element in ipairs(self) do
            if element.id == name or element:getAttribute("name") == name then
                return element
            end
        end
    end
end

return HTMLCollection
