local gumbo = require "gumbo"
local parse = assert(gumbo.parse)
local open, write, stderr = io.open, io.write, io.stderr
local clock, assert, collectgarbage = os.clock, assert, collectgarbage
local filename = assert(arg[1], "arg[1] is nil; expecting filename")
local _ENV = nil

collectgarbage()
local basemem = collectgarbage("count")
local document, duration

do
    local file = assert(open(filename))
    local text = assert(file:read("*a"))
    file:close()
    stderr:write("Parsing ", filename, "...\n")

    local start_time = clock()
    document = parse(text)
    local stop_time = clock()
    assert(document and document.body)
    duration = stop_time - start_time
end

collectgarbage()
local memory = collectgarbage("count") - basemem
local summary = "Parse time: %.2fs\nLua memory usage: %.0fKB\n"
write(summary:format(duration, memory))
