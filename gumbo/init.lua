local have_ffi, ffi = pcall(require, "ffi")
local want_ffi = os.getenv "LGUMBO_USE_FFI"
local gumbo = {}

if have_ffi == true then
    if want_ffi == "1" then
        gumbo.parse = require "gumbo.ffi-parse"
    elseif want_ffi == "0" then
        gumbo.parse = require "gumbo.parse"
    else -- use default
        if jit then -- prefer FFI for LuaJIT
            gumbo.parse = require "gumbo.ffi-parse"
        else -- prefer C module over (slow) luaffi
            gumbo.parse = require "gumbo.parse"
        end
    end
else
    if want_ffi == "1" then
        error "Explicitly requested FFI module but FFI not available"
    else
        gumbo.parse = require "gumbo.parse"
    end
end

function gumbo.parse_file(path_or_file, tab_stop)
    local file, openerr
    if type(path_or_file) == "string" then
        file, openerr = io.open(path_or_file)
        if not file then return nil, openerr end
    elseif io.type(path_or_file) == "file" then
        file = path_or_file
    else
        return nil, "Invalid argument #1: not a file handle or filename string"
    end
    local text, readerr = file:read("*a")
    file:close()
    if text then
        return gumbo.parse(text, tab_stop)
    else
        return nil, readerr
    end
end

return gumbo
