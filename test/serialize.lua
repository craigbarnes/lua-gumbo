#!/usr/bin/env lua
-- Script for serializing a lua-gumbo parse tree into various formats.
-- Can be used with the diff utility for testing against expected output.

local gumbo = require "gumbo"
local fmt = string.format

local commands = {
    html     = "Parse and serialize back to HTML",
    table    = "Parse and serialize to Lua table",
    html5lib = "Parse and serialize to html5lib tree-constructor format",
}

local function usage(fd, progname)
    fd:write("Usage: ", progname, " COMMAND [INPUT-FILE] [OUTPUT-FILE]")
    fd:write("\n\nCommands:\n\n")
    for k, v in pairs(commands) do fd:write(fmt("   %-10s  %s\n", k, v)) end
    fd:write("\n")
    os.exit(1)
end

local command = commands[arg[1]] and arg[1] or usage(io.stderr, arg[0])
local serialize = require("gumbo.serialize." .. command)
local output = arg[3] and assert(io.open(arg[3], "a")) or io.stdout
local tree = assert(gumbo.parse_file(arg[2] or io.stdin))
assert(serialize(tree, output))
