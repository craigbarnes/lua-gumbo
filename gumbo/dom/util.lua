local type, select, pairs, require = type, select, pairs, require
local _ENV = nil
local util = {}

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
            error "Invalid argument type"
        end
        for k, v in pairs(m) do
            t[k] = v
        end
    end
    t.__index = t
    return t
end

return util
