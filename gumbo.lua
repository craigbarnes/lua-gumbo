local type, open, iotype = type, io.open, io.type
local parse

if jit and jit.status() then
    local haveffi, ffi = pcall(require, "ffi")
    if haveffi then
        parse = require "gumbo.ffi-parse"
    end
end

if not parse then
    parse = require "gumbo.parse"
end

local _ENV = nil

local function parseFile(pathOrFile, tabStop)
    local file, openerr
    if type(pathOrFile) == "string" then
        file, openerr = open(pathOrFile)
        if not file then
            return nil, openerr
        end
    elseif iotype(pathOrFile) == "file" then
        file = pathOrFile
    else
        return nil, "Invalid argument #1: not a file handle or filename string"
    end
    local text, readerr = file:read("*a")
    file:close()
    if text then
        return parse(text, tabStop)
    else
        return nil, readerr
    end
end

return {
    parse = parse,
    parseFile = parseFile,
    parse_file = parseFile -- Alias for backwards compatibility
}
