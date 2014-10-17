local type, ipairs, assert = type, ipairs, assert
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
    assert(type(name) == "string")
    if name ~= "" then
        for i, element in ipairs(self) do
            if element.id == name or element:getAttribute("name") == name then
                return element
            end
        end
    end
end

return HTMLCollection
