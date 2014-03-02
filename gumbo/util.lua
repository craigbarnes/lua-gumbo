local Buffer = {}
Buffer.__index = Buffer

function Buffer:write(...)
    local n = #self
    for i = 1, select("#", ...) do
        self[n+i] = select(i, ...)
    end
end

function Buffer:__tostring()
    return table.concat(self)
end

local Indent = {}

function Indent:__index(depth)
    if depth < 25 then
        self[depth] = self[1]:rep(depth)
        return self[depth]
    else -- stop indenting at depth of 25, to avoid buffer/output bloat
        return ""
    end
end

return {
    Buffer = function()
        return setmetatable({}, Buffer)
    end,
    Indent = function(width)
        local i1 = string.rep(" ", width or 4)
        return setmetatable({[0] = "", [1] = i1}, Indent)
    end
}
