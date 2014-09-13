#!/usr/bin/env lua
-- Script for serializing a lua-gumbo parse tree into various formats.
-- Can be used with the diff utility for testing against expected output.

local gumbo = require "gumbo"
local stderr = io.stderr
local progname = arg[0]

local commands = {
    html     = "Parse and serialize back to HTML",
    table    = "Parse and serialize to Lua table",
    html5lib = "Parse and serialize to html5lib AST",
}

local function usage()
    stderr:write("Usage: ", progname, " COMMAND [INPUT-FILE] [OUTPUT-FILE]")
    stderr:write("\n\nCommands:\n\n")
    for command, description in pairs(commands) do
        stderr:write(string.format("   %-10s  %s\n", command, description))
    end
    stderr:write("\n")
    os.exit(1)
end

local command = commands[arg[1]] and arg[1] or usage()
local serialize = require("gumbo.serialize." .. command)
local output = arg[3] and assert(io.open(arg[3], "a")) or io.stdout
local tree = assert(gumbo.parse_file(arg[2] or io.stdin))
assert(serialize(tree, output))
