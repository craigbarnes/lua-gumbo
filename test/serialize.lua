#!/usr/bin/env lua
-- Script for serializing a lua-gumbo parse tree into various formats.
-- Can be used with the diff utility for testing against expected output.

local gumbo = require "gumbo"

local usage = [[
Usage: %s COMMAND [INPUT-FILE] [OUTPUT-FILE]

Commands:

   html            Parse and serialize back to HTML
   table           Parse and serialize to Lua table
   html5lib        Parse and serialize to html5lib tree-constructor format
   bench_COMMAND   Run COMMAND in benchmark mode (full buffering, no printing)
   help            Print usage information and exit

]]

local commands = setmetatable({
    help = function() io.stdout:write(string.format(usage, arg[0])) end,
}, {
    __index = function(self, key)
        assert(type(key) == "string")
        local benchcmd = key:match "^bench_(.+)"
        local module = benchcmd or key
        local exists, serialize = pcall(require, "gumbo.serialize." .. module)
        if exists then
            return function(input, output)
                local document = assert(gumbo.parse_file(input))
                assert(serialize(document, not benchcmd and output or nil))
            end
        else
            return self.help
        end
    end
})

local input = arg[2] or io.stdin
local output = arg[3] and assert(io.open(arg[3], "a")) or io.stdout
commands[arg[1] or "help"](input, output)
