local type, pairs, error = type, pairs, error
local getmetatable, setmetatable = getmetatable, setmetatable
local _ENV = nil
local Set = {}
Set.__index = Set

local function addKeys(set, t)
    for member in pairs(t) do
        set[member] = true
    end
end

local function addValues(set, t)
    for i = 1, #t do
        set[t[i]] = true
    end
end

local function addWords(set, s)
    for member in s:gmatch("%S+") do
        set[member] = true
    end
end

function Set:union(other)
    local union = {}
    local type = type(other)
    if type == "table" then
        if getmetatable(other) == Set then
            addKeys(union, other)
        else
            addValues(union, other)
        end
    elseif type == "string" then
        addWords(union, other)
    else
        error("Invalid argument type; expecting Set, table or string", 2)
    end
    for member in pairs(self) do
        union[member] = true
    end
    return setmetatable(union, Set)
end

Set.__add = Set.union

local function constructor(members)
    local set = {}
    local type = type(members)
    if type == "table" then
        addValues(set, members)
    elseif type == "string" then
        addWords(set, members)
    else
        error("Invalid argument type; expecting table or string", 2)
    end
    return setmetatable(set, Set)
end

return constructor
