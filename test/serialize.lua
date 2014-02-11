#!/usr/bin/env lua
-- Script for serializing a lua-gumbo parse tree into various formats.
-- Can be used with the diff utility for testing against expected output.

local gumbo = require "gumbo"
local commands = {}
setmetatable(commands, commands)

local usage = [[
Usage: %s COMMAND [INPUT-FILE] [OUTPUT-FILE]

Commands:

   html            Parse and serialize back to HTML
   table           Parse and serialize to Lua table
   html5lib        Parse and serialize to html5lib tree-constructor format
   parse           Parse and exit (for benchmarking)
   help            Print usage information and exit

]]

function commands.help()
    io.stdout:write(string.format(usage, arg[0]))
end

function commands.parse(input)
    return assert(gumbo.parse_file(input))
end

function commands.__index(self, key)
    if type(key) == "string" then
        local exists, serialize = pcall(require, "gumbo.serialize." .. key)
        if exists then
            return function(input, output)
                assert(serialize(self.parse(input), output))
            end
        end
    end
    return self.help
end

local input = arg[2] or io.stdin
local output = arg[3] and assert(io.open(arg[3], "a")) or io.stdout
commands[arg[1]](input, output)
