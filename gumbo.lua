local type, open, iotype = type, io.open, io.type
local assert, error = assert, error
local parse

if jit and jit.status() then
    local haveffi = pcall(require, "ffi")
    if haveffi then
        parse = require "gumbo.ffi-parse"
    end
end

if not parse then
    parse = require "gumbo.parse"
end

local _ENV = nil

local function parseFile(pathOrFile, ctx, ctxns, tabStop)
    assert(ctx == nil or type(ctx) == "string")
    assert(ctxns == nil or type(ctxns) == "string")
    local file, openerr
    local closeAfterRead = false
    if type(pathOrFile) == "string" then
        file, openerr = open(pathOrFile)
        if not file then
            return nil, openerr
        end
        closeAfterRead = true
    elseif iotype(pathOrFile) == "file" then
        file = pathOrFile
    else
        error("Invalid argument #1: not a file handle or filename string")
    end
    local text, readerr = file:read("*a")
    if closeAfterRead == true then
        file:close()
    end
    if text then
        return parse(text, ctx, ctxns, tabStop)
    else
        return nil, readerr
    end
end

return {
    parse = parse,
    parseFile = parseFile,
    parse_file = parseFile -- Alias for backwards compatibility
}
