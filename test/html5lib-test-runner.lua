#!/usr/bin/lua
local re = require "re"
local gumbo = require "gumbo"
local serialize = require "gumbo.serialize.html5lib"
local verbose = os.getenv "VERBOSE"
local total_pass = 0
local total_fail = 0

-- TODO: Make `data` accept multiple lines
local grammar = re.compile [[
    blocks   <- {| block* |} eof
    block    <- {| data errors document nl* |}
    data     <- '#data' nl {:data: nothash [^%nl]* :} nl
    errors   <- '#errors' nl (nothash line)+
    document <- '#document' nl {:document: ("|" line)+ :}
    nl       <- %nl
    line     <- [^%nl]* %nl
    nothash  <- [^#]
    eof      <- !.
]]

local function basename(str)
    return str:gsub("(.*/)(.*)", "%2")
end

local function warn(...)
    io.stderr:write(string.format(...))
end

local function runtests(filename, tests)
    local pass = 0
    local fail = 0
    for i = 1, #tests do
        local test = tests[i]
        local document = assert(gumbo.parse(test.data))
        local serialized = serialize(document)
        if serialized == test.document then
            pass = pass + 1
        else
            fail = fail + 1
            if verbose then
                warn("\n===========================================\n")
                warn("Test #%d in %s failed:\n\n", i, filename)
                warn("Input:\n%s\n\n", test.data)
                warn("Expected:\n%s\n", test.document)
                warn("Got:\n%s\n", serialized)
                warn("===========================================\n\n")
            end
        end
    end
    local fmt = "%s: %d tests passed, %d tests failed\n"
    io.stdout:write(string.format(fmt, basename(filename), pass, fail))
    total_pass = total_pass + pass
    total_fail = total_fail + fail
end

assert(arg[1], "No test files specified")

for i = 1, #arg do
    local filename = arg[i]
    local file = assert(io.open(filename))
    local text = assert(file:read("*a"))
    file:close()
    local tests = grammar:match(text)
    if tests then
        runtests(filename, tests)
    else
        warn("\27[31m%s: failed to parse data\27[0m\n", basename(filename))
    end
end

local fmt = "\nTOTAL: %d tests passed, %d tests failed\n\n"
io.stdout:write(string.format(fmt, total_pass, total_fail))
