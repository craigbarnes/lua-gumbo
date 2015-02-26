local type, pairs, error = type, pairs, error
local setmetatable = setmetatable
local _ENV = nil
local Set = {}
Set.__index = Set

local function assertSet(v)
    if not (v and type(v) == "table" and v.union) then
        error("TypeError: Argument is not a Set", 3)
    end
end

function Set:union(other)
    assertSet(self)
    assertSet(other)
    local union = {}
    for member in pairs(self) do
        union[member] = true
    end
    for member in pairs(other) do
        union[member] = true
    end
    return setmetatable(union, Set)
end

function Set:isSubsetOf(other)
    assertSet(self)
    assertSet(other)
    for member in pairs(self) do
        if not other[member] then
            return false
        end
    end
    return true
end

Set.__add = Set.union

function Set:__eq(other)
    return self:isSubsetOf(other) and other:isSubsetOf(self)
end

local function constructor(members)
    local set = {}
    if members ~= nil then
        local type = type(members)
        if type == "table" then
            for i = 1, #members do
                set[members[i]] = true
            end
        elseif type == "string" then
            for member in members:gmatch("%S+") do
                set[member] = true
            end
        else
            error("Invalid argument type; expecting table or string", 2)
        end
    end
    return setmetatable(set, Set)
end

return constructor
