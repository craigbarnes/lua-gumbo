local gumbo = require "gumbo"
local parse = gumbo.parse
local open, write, stderr = io.open, io.write, io.stderr
local clock, assert, collectgarbage = os.clock, assert, collectgarbage
local filename = assert(arg[1], "arg[1] is nil; expecting filename")
local _ENV = nil
local document, duration

collectgarbage()
local basemem = collectgarbage("count")

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

write(("Parse time: %.2fs\nLua memory usage: %dKB\n"):format(duration, memory))
