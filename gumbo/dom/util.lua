local type, select, pairs, require = type, select, pairs, require
local assert = assert
local _ENV = nil

local util = {
    -- TODO: Implement full Name pattern from http://www.w3.org/TR/xml/#NT-Name
    namePattern = "^[A-Za-z:_][A-Za-z0-9:_.-]*$"
}

function util.merge(...)
    local t = {}
    for i = 1, select("#", ...) do
        local arg = select(i, ...)
        local argtype = type(arg)
        local m
        if argtype == "string" then
            m = require("gumbo.dom." .. arg)
        elseif argtype == "table" then
            m = arg
        else
            assert(false, "Invalid argument type")
        end
        for k, v in pairs(m) do
            local tk = t[k]
            if type(v) == "table" and type(tk) == "table" then
                for k2, v2 in pairs(v) do
                    tk[k2] = v2
                end
            else
                t[k] = v
            end
        end
    end
    t.__index = t
    return t
end

return util
