local useffi = jit and jit.status() and pcall(require, "ffi")
local parse = useffi and require "gumbo.ffi-parse" or require "gumbo.parse"
local type, open, iotype = type, io.open, io.type
local assert, error = assert, error
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
