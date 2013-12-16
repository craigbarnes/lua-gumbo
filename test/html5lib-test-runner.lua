#!/usr/bin/lua
local re = require "re"
local gumbo = require "gumbo"
local serialize = require "gumbo.serialize.html5lib"
local verbose = os.getenv "VERBOSE"

local results = {
    pass = 0,
    fail = 0,
    parsed = 0,
    not_parsed = 0
}

local grammar = re.compile [[
    blocks   <- {| block* |} eof
    block    <- {| data errors document nl* |}
    data     <- '#data' nl {:data: lines :} nl
    errors   <- '#errors' nl (lines nl)?
    document <- '#document' nl {:document: ("|" line)+ :}
    lines    <- [^#] [^%nl]* (%nl [^#] [^%nl]*)*
    line     <- [^%nl]* %nl
    nl       <- %nl
    eof      <- !.
]]

local function basename(str)
    return str:gsub("(.*/)(.*)", "%2")
end

local function printf(...)
    io.stdout:write(string.format(...))
end

local function runtests(filename, tests)
    local result = {
        filename = filename,
        basename = basename(filename),
        parsed = true,
        pass = 0,
        fail = 0
    }
    for i = 1, #tests do
        local test = tests[i]
        local document = assert(gumbo.parse(test.data))
        local serialized = serialize(document)
        if serialized == test.document then
            result.pass = result.pass + 1
        else
            result.fail = result.fail + 1
            if verbose then
                printf("\n===========================================\n")
                printf("Test #%d in %s failed:\n\n", i, filename)
                printf("Input:\n%s\n\n", test.data)
                printf("Expected:\n%s\n", test.document)
                printf("Got:\n%s\n", serialized)
                printf("===========================================\n\n")
            end
        end
    end
    table.insert(results, result)
    results.pass = results.pass + result.pass
    results.fail = results.fail + result.fail
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
        results.parsed = results.parsed + 1
    else
        table.insert(results, {
            filename = filename,
            basename = basename(filename),
            parsed = false
        })
        results.not_parsed = results.not_parsed + 1
    end
end

for i = 1, #results do
    local result = results[i]
    if result.parsed then
        printf("%s: %d passed, %d failed\n", result.basename, result.pass, result.fail)
    else
        printf("%s: \27[31mfailed to parse data\27[0m\n", result.basename)
    end
end

printf([[

Totals:

   Files loaded: %d
   Files failed: %d
   Tests passed: %d
   Tests failed: %d

]], results.parsed, results.not_parsed, results.pass, results.fail)
