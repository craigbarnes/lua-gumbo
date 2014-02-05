local Indent = {}

function Indent:__index(i)
    self[i] = self[1]:rep(i)
    return self[i]
end

function Indent.new(width)
    local i1 = string.rep(" ", width or 4)
    return setmetatable({[0] = "", [1] = i1}, Indent)
end

return Indent.new
