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

local function printf(...)
    io.stdout:write(string.format(...))
end

local function memory_usage()
    collectgarbage()
    local a, b = string.match(collectgarbage("count") ,'^(%d)(%d*)(.-)$')
    return a .. b:reverse():gsub('(%d%d%d)', '%1,'):reverse()
end

local function help()
    io.stdout:write(string.format(usage, arg[0]))
end

local function bench(input)
    local start = os.clock()
    local liveref = assert(gumbo.parse_file(input))
    printf("%.2fs  %sKB\n", os.clock() - start, memory_usage())
end

local commands = setmetatable({
    help = help,
    bench = bench
}, {
    __index = function(self, k)
        if type(k) == "string" then
            local exists, serialize = pcall(require, "gumbo.serialize." .. k)
            if exists then
                return function(input, output)
                    local document = assert(gumbo.parse_file(input))
                    serialize(document, output)
                end
            end
        end
        return self.help
    end
})

local input = (arg[2] and arg[2] ~= "-") and assert(open(arg[2])) or io.stdin
local output = arg[3] and assert(open(arg[3], "a")) or io.stdout
commands[arg[1]](input, output)
