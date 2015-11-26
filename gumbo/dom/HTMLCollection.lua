local util = require "gumbo.dom.util"
local assertString = util.assertString
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

function HTMLCollection:namedItem(key)
    assertString(key)
    if key == "" then
        return nil
    end
    for _, element in ipairs(self) do
        if element:getAttribute("id") == key then
            return element
        elseif
            element.namespaceURI == "http://www.w3.org/1999/xhtml"
            and element:getAttribute("name") == key
        then
            return element
        end
    end
end

return HTMLCollection
