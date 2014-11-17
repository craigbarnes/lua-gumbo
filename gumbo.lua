local parse

if jit and jit.status() then
    local have_ffi, ffi = pcall(require, "ffi")
    if have_ffi then
        parse = require "gumbo.ffi-parse"
    end
end

if not parse then
    parse = require "gumbo.parse"
end

local type, open, iotype = type, io.open, io.type
local _ENV = nil

local function parse_file(path_or_file, tab_stop)
    local file, openerr
    if type(path_or_file) == "string" then
        file, openerr = open(path_or_file)
        if not file then
            return nil, openerr
        end
    elseif iotype(path_or_file) == "file" then
        file = path_or_file
    else
        return nil, "Invalid argument #1: not a file handle or filename string"
    end
    local text, readerr = file:read("*a")
    file:close()
    if text then
        return parse(text, tab_stop)
    else
        return nil, readerr
    end
end

return {
    parse = parse,
    parse_file = parse_file,
}
