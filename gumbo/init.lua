local have_ffi, ffi = pcall(require, "ffi")
local gumbo

local function debug_print(msg)
    if os.getenv "LGUMBO_DEBUG" then
        io.stderr:write(msg)
    end
end

if have_ffi == true and not os.getenv "LGUMBO_NOFFI" then
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
