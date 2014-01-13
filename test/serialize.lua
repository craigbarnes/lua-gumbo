#!/usr/bin/env lua
-- Script for serializing a lua-gumbo parse tree into various formats.
-- Can be used with the diff utility for testing against expected output.

local gumbo = require "gumbo"
local open = io.open

local usage = [[
Usage: %s COMMAND [INPUT-FILE] [OUTPUT-FILE]

Commands:

   html     Parse and serialize back to HTML
   table    Parse and serialize to Lua table
   tree     Parse and serialize to html5lib tree-constructor format
   bench    Parse and print CPU time and memory usage information
   help     Print usage information and exit

]]

local commands = setmetatable({}, {__index = function(s) return s.help end})

function commands.help()
    io.stdout:write(string.format(usage, arg[0]))
end

function commands.html(input, output)
    local to_html = require "gumbo.serialize.html"
    local document = assert(gumbo.parse_file(input))
    to_html(document, output)
end

function commands.table(input, output)
    local to_table = require "gumbo.serialize.table"
    local document = assert(gumbo.parse_file(input))
    to_table(document, output)
end

function commands.tree(input, output)
    local to_tree = require "gumbo.serialize.html5lib"
    local document = assert(gumbo.parse_file(input))
    to_tree(document, output)
end

function commands.bench(input)
    local start = os.clock()
    local liveref = assert(gumbo.parse_file(input))
    local elapsed = os.clock() - start
    collectgarbage()
    local gcmem = collectgarbage("count")
    io.stderr:write(string.format("%.2fs, %dKB\n", elapsed, gcmem))
end

local input = (arg[2] and arg[2] ~= "-") and assert(open(arg[2])) or io.stdin
local output = arg[3] and assert(open(arg[3], "a")) or io.stdout
commands[arg[1]](input, output)
