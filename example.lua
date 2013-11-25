#!/usr/bin/env lua

local gumbo = require "gumbo"

local usage = [[
Usage: %s COMMAND FILENAME

Commands:

   html     Parse and serialize back to HTML
   table    Parse and serialize to Lua table constructor syntax
   bench    Parse and exit (for timing the parser via another utility)
   help     Print usage information and exit

]]

local function check(cond, msg)
    if not cond then
        local fmt = "Error: %s\nTry '%s help' for more information\n"
        io.stderr:write(string.format(fmt, msg, arg[0]))
        os.exit(1)
    end
end

local function parse_file(filename)
    local file, err = io.open(filename)
    if file then
        local text = file:read("*a")
        file:close()
        return gumbo.parse(text)
    else
        check(false, err)
    end
end

local action = {
    help = function()
        io.stdout:write(string.format(usage, arg[0]))
    end,
    html = function(filename)
        local serialize = require("gumbo.serialize").to_html
        local document = parse_file(filename)
        io.stdout:write(serialize(document))
    end,
    table = function(filename)
        local serialize = require("gumbo.serialize").to_table
        local document = parse_file(filename)
        io.stdout:write(serialize(document))
    end,
    bench = function(filename)
        parse_file(filename)
    end
}

local command = arg[1]
local filename = arg[2]
check(command, "no command specified")
check(action[command], "invalid command")
check(filename or command == "help", "no filename specified")
action[command](filename)
