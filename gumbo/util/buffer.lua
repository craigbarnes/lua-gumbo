local Buffer = {}
Buffer.__index = Buffer

function Buffer:append(str)
    self.n = self.n + 1
    self[self.n] = str
end

function Buffer:appendf(...)
    self:append(string.format(...))
end

function Buffer:concat(sep)
    return table.concat(self, sep)
end

function Buffer.new()
    return setmetatable({n = 0}, Buffer)
end

return Buffer.new
