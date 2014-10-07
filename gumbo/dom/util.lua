local type, select, pairs, require = type, select, pairs, require
local _ENV = nil

local util = {
    -- TODO: Implement full Name pattern from http://www.w3.org/TR/xml/#NT-Name
    namePattern = "^[A-Za-z:_][A-Za-z0-9:_.-]*$"
}

function util.merge(...)
    local t = {}
    local g = {}
    for i = 1, select("#", ...) do
        local arg = select(i, ...)
        local argtype = type(arg)
        local m
        if argtype == "string" then
            m = require("gumbo.dom." .. arg)
        elseif argtype == "table" then
            m = arg
        else
            error "Invalid argument type"
        end
        for k, v in pairs(m) do
            if k ~= "getters" and k ~= "setters" then
                t[k] = v
            end
        end
        if m.getters then
            for k, v in pairs(m.getters) do
                g[k] = v
            end
        end
    end
    t.getters = g
    t.__index = t
    return t
end

return util
