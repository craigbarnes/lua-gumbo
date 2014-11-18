local select, tconcat, setmetatable = select, table.concat, setmetatable
local _ENV = nil
local Buffer = {}
Buffer.__index = Buffer

function Buffer:write(...)
    local length = #self
    for i = 1, select("#", ...) do
        length = length + 1
        self[length] = select(i, ...)
    end
end

function Buffer:tostring()
    return tconcat(self)
end

Buffer.__tostring = Buffer.tostring

return function()
    return setmetatable({}, Buffer)
end
