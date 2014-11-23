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

function Buffer:tostring()
    return tconcat(self)
end

Buffer.__tostring = Buffer.tostring

-- TODO: Allow specifying the number of array slots to pre-allocate.
--       Buffers are almost always discarded shortly after creation,
--       so setting a small default value for this would probably not
--       waste much memory and would avoid the first few re-hashes.
return function()
    return setmetatable({length = 0}, Buffer)
end
