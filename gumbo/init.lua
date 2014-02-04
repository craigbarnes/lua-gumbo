local gumbo = require "gumbo.parse"

-- TODO: Move this into parse.c
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
