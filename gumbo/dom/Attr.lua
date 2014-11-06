local _ENV = nil

local Attr = {
    specified = true,
    getters = {}
}

local getters = Attr.getters

function Attr:__index(k)
    local field = Attr[k]
    if field then
        return field
    else
        local getter = getters[k]
        if getter then
            return getter(self)
        end
    end
end

function Attr.getters:localName()
    return self.name
end

function Attr.getters:textContent()
    return self.value
end

local escmap = {
    ["&"] = "&amp;",
    ['"'] = "&quot;"
}

function Attr.getters:escapedValue()
    return (self.value:gsub('[&"]', escmap):gsub("\xC2\xA0", "&nbsp;"))
end

return Attr
