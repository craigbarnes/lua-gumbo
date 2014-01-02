#!/usr/bin/env lua

local gumbo = require "gumbo"

local usage = [[
Usage: %s COMMAND [FILENAME]

Commands:

   html     Parse and serialize back to HTML
   tree     Parse and serialize to html5lib tree-constructor format
   table    Parse and serialize to Lua table (using gumbo.serialize.table)
   serpent  Parse and serialize to Lua table (using external Serpent library)
   bench    Parse and exit (for timing the parser via another utility)
   help     Print usage information and exit

]]

local actions = {
    help = function()
        io.stdout:write(string.format(usage, arg[0]))
    end,
    html = function(file)
        local serialize = require "gumbo.serialize.html"
        local document = assert(gumbo.parse_file(file))
        io.stdout:write(serialize(document))
    end,
    table = function(file)
        local serialize = require "gumbo.serialize.table"
        local document = assert(gumbo.parse_file(file))
        io.stdout:write(serialize(document))
    end,
    serpent = function(file)
        local serpent = require "serpent"
        local document = assert(gumbo.parse_file(file))
        local options = {comment = false, indent = "    "}
        io.stdout:write(serpent.block(document, options), '\n')
    end,
    html5lib = function(file)
        local serialize = require "gumbo.serialize.html5lib"
        local document = assert(gumbo.parse_file(file))
        io.stdout:write(serialize(document))
    end,
    bench = function(file)
        assert(gumbo.parse_file(file))
    end
}

(actions[arg[1]] or actions.help)(arg[2] or io.stdin)
