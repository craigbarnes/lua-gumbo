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

return function()
    return setmetatable({}, Buffer)
end
