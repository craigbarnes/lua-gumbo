local Indent = {}

function Indent:__index(i)
    self[i] = self[1]:rep(i)
    return self[i]
end

function Indent.new(indent)
    if type(indent) == "number" then indent = string.rep(" ", indent) end
    return setmetatable({[0] = "", [1] = indent or "    "}, Indent)
end

return Indent.new
