local type, select, pairs = type, select, pairs
local assert, error, rawset = assert, error, rawset
local _ENV = nil
local util = {}

function util.merge(...)
    local t = {getters={}}
    for i = 1, select("#", ...) do
        local m = select(i, ...)
        assert(type(m) == "table")
        for k, v in pairs(m) do
            local tk = t[k]
            if type(v) == "table" and type(tk) == "table" then
                for k2, v2 in pairs(v) do
                    tk[k2] = v2
                end
            else
                t[k] = v
            end
        end
    end
    t.__index = util.indexFactory(t)
    t.__newindex = util.newindexFactory(t)
    return t
end

function util.indexFactory(t)
    local getters = assert(t.getters)
    return function(self, k)
        local field = t[k]
        if field then
            return field
        else
            local getter = getters[k]
            if getter then
                return getter(self)
            end
        end
    end
end

function util.newindexFactory(t)
    local setters = assert(t.setters)
    local readonly = assert(t.readonly)
    return function(self, k, v)
        local setter = setters[k]
        if setter then
            setter(self, v)
        elseif not readonly[k] then
            rawset(self, k, v)
        end
    end
end

-- TODO: Better error messages

function util.assertNode(v)
    if not (v and type(v) == "table" and v.nodeType) then
        error("TypeError: Argument is not a Node", 3)
    end
end

function util.assertDocument(v)
    if not (v and type(v) == "table" and v.type == "document") then
        error("TypeError: Argument is not a Document", 3)
    end
end

function util.assertElement(v)
    if not (v and type(v) == "table" and v.type == "element") then
        error("TypeError: Argument is not an Element", 3)
    end
end

function util.assertTextNode(v)
    if not (v and type(v) == "table" and v.nodeName == "#text") then
        error("TypeError: Argument is not a Text node", 3)
    end
end

function util.assertComment(v)
    if not (v and type(v) == "table" and v.type == "comment") then
        error("TypeError: Argument is not a Comment", 3)
    end
end

function util.assertString(v)
    if type(v) ~= "string" then
        error("TypeError: Argument is not a string", 3)
    end
end

function util.assertStringOrNil(v)
    if v ~= nil and type(v) ~= "string" then
        error("TypeError: Argument is not a string", 3)
    end
end

function util.assertName(v)
    if type(v) ~= "string" then
        error("TypeError: Argument is not a string", 3)
    elseif not v:find("^[A-Za-z:_][A-Za-z0-9:_.-]*$") then
        -- TODO: If ASCII name pattern isn't found, try full Unicode match
        --       before throwing an error.
        --       See: http://www.w3.org/TR/xml/#NT-Name
        error("InvalidCharacterError", 3)
    end
end

function util.NYI()
    error("Not yet implemented", 2)
end

return util
