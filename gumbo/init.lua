local have_ffi, ffi = pcall(require, "ffi")
local want_ffi = os.getenv "LGUMBO_USE_FFI"
local gumbo

if have_ffi == true then
    if want_ffi == "1" then
        gumbo = require "gumbo.ffi"
    elseif want_ffi == "0" then
        gumbo = require "cgumbo"
    else -- use default
        if jit then -- prefer FFI for LuaJIT
            gumbo = require "gumbo.ffi"
        else -- prefer C module over (slow) luaffi
            gumbo = require "cgumbo"
        end
    end
else
    if want_ffi == "1" then
        error "Explicitly requested FFI module but FFI not available"
    else
        gumbo = require "cgumbo"
    end
end

function gumbo.parse_file(filename, tab_stop)
    local file, openerr = io.open(filename)
    if file then
        local text, readerr = file:read("*a")
        file:close()
        if text then
            return gumbo.parse(text, tab_stop)
        else
            return nil, readerr
        end
    else
        return nil, openerr
    end
end

return gumbo
