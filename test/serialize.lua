#!/usr/bin/env lua

local gumbo = require "gumbo"

local usage = [[
Usage: %s COMMAND FILENAME

Commands:

   html     Parse and serialize back to HTML
   table    Parse and serialize to Lua table using gumbo.serialize.table
   serpent  Parse and serialize to Lua table using Serpent
   bench    Parse and exit (for timing the parser via another utility)
   help     Print usage information and exit

]]

local function check(cond, msg)
    if not cond then
        local fmt = "Error: %s\nTry '%s help' for more information\n"
        io.stderr:write(string.format(fmt, msg, arg[0]))
        os.exit(1)
    else
        return cond
    end
end

local actions = {
    help = function()
        io.stdout:write(string.format(usage, arg[0]))
    end,
    html = function(filename)
        local serialize = require "gumbo.serialize.html"
        local document = check(gumbo.parse_file(filename))
        io.stdout:write(serialize(document))
    end,
    table = function(filename)
        local serialize = require "gumbo.serialize.table"
        local document = check(gumbo.parse_file(filename))
        io.stdout:write(serialize(document))
    end,
    serpent = function(filename)
        local serpent = require "serpent"
        local document = check(gumbo.parse_file(filename))
        local options = {comment = false, indent = "    "}
        io.stdout:write(serpent.block(document, options), '\n')
    end,
    html5lib = function(filename)
        local serialize = require "gumbo.serialize.html5lib"
        local document = check(gumbo.parse_file(filename))
        io.stdout:write(serialize(document))
    end,
    bench = function(filename)
        check(gumbo.parse_file(filename))
    end
}

local command = check(arg[1], "no command specified")
local action = check(actions[command], "invalid command")
local filename = check(command == "help" and "" or arg[2], "missing filename")
action(filename)
