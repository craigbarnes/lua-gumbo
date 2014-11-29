local type, ipairs, error = type, ipairs, error
local _ENV = nil

local function Set(members)
    local type = type(members)
    local set = {}
    if type == "table" then
        for i, member in ipairs(members) do
            set[member] = true
        end
    elseif type == "string" then
        for member in members:gmatch("%S+") do
            set[member] = true
        end
    else
        error("Invalid argument type; expecting table or string", 2)
    end
    return set
end

return Set
