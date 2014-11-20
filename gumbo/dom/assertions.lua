local type, error = type, error
local _ENV = nil
local namePattern = "^[A-Za-z:_][A-Za-z0-9:_.-]*$"

-- TODO: Implement full Name pattern from http://www.w3.org/TR/xml/#NT-Name
-- TODO: Better error messages

local function assertNode(v)
    if not (v and type(v) == "table" and v.nodeType) then
        error("TypeError: Argument is not a Node", 3)
    end
end

local function assertString(v)
    if type(v) ~= "string" then
        error("TypeError: Argument is not a string", 3)
    end
end

local function assertNilableString(v)
    if v ~= nil and type(v) ~= "string" then
        error("TypeError: Argument is not a string", 3)
    end
end

local function assertName(v)
    if type(v) ~= "string" then
        error("TypeError: Argument is not a string", 3)
    elseif not v:find(namePattern) then
        error("InvalidCharacterError", 3)
    end
end

local function NYI()
    error("Not yet implemented", 2)
end

return {
    assertNode = assertNode,
    assertString = assertString,
    assertNilableString = assertNilableString,
    assertName = assertName,
    NYI = NYI
}
