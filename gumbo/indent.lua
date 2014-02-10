local Indent = {}

function Indent:__index(depth)
    if depth < 25 then
        self[depth] = self[1]:rep(depth)
        return self[depth]
    else -- stop indenting at depth of 25, to avoid buffer/output bloat
        return ""
    end
end

function Indent.new(width)
    local i1 = string.rep(" ", width or 4)
    return setmetatable({[0] = "", [1] = i1}, Indent)
end

return Indent.new
