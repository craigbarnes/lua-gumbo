local parse = require "gumbo.parse"
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
    -- GumboParseFlags:
    insertion_by_parser = 2^0,
    implicit_end_tag = 2^1,
    insertion_implied = 2^3,
    converted_from_end_tag = 2^4,
    insertion_from_isindex = 2^5,
    insertion_from_image = 2^6,
    reconstructed_formatting_element = 2^7,
    adoption_agency_cloned = 2^8,
    adoption_agency_moved = 2^9,
    foster_parented = 2^10
}
