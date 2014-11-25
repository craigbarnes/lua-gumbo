local type, error = type, error
local _ENV = nil

-- TODO: Better error messages

local function assertNode(v)
    if not (v and type(v) == "table" and v.nodeType) then
        error("TypeError: Argument is not a Node", 3)
    end
end

local function assertDocument(v)
    if not (v and type(v) == "table" and v.type == "document") then
        error("TypeError: Argument is not a Document", 3)
    end
end

local function assertElement(v)
    if not (v and type(v) == "table" and v.type == "element") then
        error("TypeError: Argument is not an Element", 3)
    end
end

local function assertTextNode(v)
    if not (v and type(v) == "table" and v.nodeName == "#text") then
        error("TypeError: Argument is not a Text node", 3)
    end
end

local function assertComment(v)
    if not (v and type(v) == "table" and v.type == "comment") then
        error("TypeError: Argument is not a Comment", 3)
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
    elseif not v:find("^[A-Za-z:_][A-Za-z0-9:_.-]*$") then
        -- TODO: If ASCII name pattern isn't found, try full Unicode match
        --       before throwing an error.
        --       See: http://www.w3.org/TR/xml/#NT-Name
        error("InvalidCharacterError", 3)
    end
end

local function NYI()
    error("Not yet implemented", 2)
end

return {
    assertNode = assertNode,
    assertDocument = assertDocument,
    assertElement = assertElement,
    assertTextNode = assertTextNode,
    assertComment = assertComment,
    assertString = assertString,
    assertNilableString = assertNilableString,
    assertName = assertName,
    NYI = NYI
}
