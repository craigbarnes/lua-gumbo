local setmetatable = setmetatable
local _ENV = nil
local Indent = {}

function Indent:__index(depth)
    if depth < 25 then
        local indent = self[1]:rep(depth)
        self[depth] = indent
        return indent
    else -- stop indenting at depth of 25, to avoid buffer/output bloat
        return ""
    end
end

return function(width)
    local i1 = (" "):rep(width or 4)
    return setmetatable({[0] = "", [1] = i1}, Indent)
end
