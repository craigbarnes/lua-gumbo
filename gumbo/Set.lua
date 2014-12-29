local type, pairs, error = type, pairs, error
local getmetatable, setmetatable = getmetatable, setmetatable
local _ENV = nil
local Set = {}
Set.__index = Set

local function assertSet(v)
    if not (v and type(v) == "table" and v.union) then
        error("TypeError: Argument is not a Set", 3)
    end
end

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
Set.__lt = Set.isSubsetOf

function Set:__eq(other)
    return self:isSubsetOf(other) and other:isSubsetOf(self)
end

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
