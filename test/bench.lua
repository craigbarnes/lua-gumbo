#!/usr/bin/env lua
local basemem = collectgarbage("count")
local document, duration

do
    local gumbo = require "gumbo"
    local parse = gumbo.parse
    local have_socket, socket = pcall(require, "socket")
    local clock = have_socket and socket.gettime or os.clock

    local filename = assert(arg[1], "arg[1] is nil; expecting filename")
    local file = assert(io.open(filename))
    local text = assert(file:read("*a"))
    file:close()
    io.stderr:write("Parsing ", filename, "...\n")

    local start_time = clock()
    document = parse(text)
    local stop_time = clock()
    assert(document and document.documentElement)
    duration = stop_time - start_time
end

collectgarbage()
local memory = collectgarbage("count") - basemem

local s = "Parse time: %.2fs\nLua memory usage: %dKB\n"
io.write(string.format(s, duration, memory))
