local select, tconcat, setmetatable = select, table.concat, setmetatable
local _ENV = nil
local Buffer = {}
Buffer.__index = Buffer

function Buffer:write(...)
    local length = self.length
    for i = 1, select("#", ...) do
        length = length + 1
        self[length] = select(i, ...)
    end
    self.length = length
end

function Buffer:__tostring()
    return tconcat(self)
end

return function()
    return setmetatable({length = 0}, Buffer)
end
