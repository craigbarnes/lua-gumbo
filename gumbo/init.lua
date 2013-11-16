local have_ffi, ffi = pcall(require, "ffi")
local want_ffi = os.getenv "LGUMBO_USE_FFI"
local use_ffi
local gumbo

if have_ffi == true then
    if want_ffi == "1" then
        use_ffi = true
    elseif want_ffi == "0" then
        use_ffi = false
    else
        if jit then -- prefer FFI for LuaJIT
            use_ffi = true
        else -- prefer C module over (slow) luaffi
            use_ffi = false
        end
    end
end

local function debug_print(msg)
    if os.getenv "LGUMBO_DEBUG" then
        io.stderr:write(msg)
    end
end

if use_ffi == true then
    gumbo = require "gumbo.ffi"
    debug_print "Using FFI  "
else -- load the C module instead
    gumbo = require "cgumbo"
    debug_print "Using C module  "
end

function gumbo.parse_file(filename, tab_stop)
    local file, err = io.open(filename)
    if file then
        local text = file:read("*a")
        file:close()
        return gumbo.parse(text, tab_stop)
    else
        return nil, err
    end
end

return gumbo
