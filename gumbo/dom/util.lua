local type, select, pairs, require = type, select, pairs, require
local assert, rawset = assert, rawset
local _ENV = nil

local util = {}

function util.merge(...)
    local t = {getters={}}
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
    return t
end

function util.indexFactory(t)
    local getters = assert(t.getters)
    return function(self, k)
        local field = t[k]
        if field then
            return field
        else
            local getter = getters[k]
            if getter then
                return getter(self)
            end
        end
    end
end

function util.newindexFactory(t)
    local setters = assert(t.setters)
    local readonly = assert(t.readonly)
    return function(self, k, v)
        local setter = setters[k]
        if setter then
            setter(self, v)
        elseif not readonly[k] then
            rawset(self, k, v)
        end
    end
end

return util
