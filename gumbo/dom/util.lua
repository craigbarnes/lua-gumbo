local util = {}

function util.implements(...)
    local t = {}
    for i = 1, select("#", ...) do
        local m = require("gumbo.dom." .. select(i, ...))
        for k, v in pairs(m) do
            t[k] = v
        end
    end
    t.__index = t
    return t
end

return util
