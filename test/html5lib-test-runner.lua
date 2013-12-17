#!/usr/bin/lua
local gumbo = require "gumbo"
local serialize = require "gumbo.serialize.html5lib"
local util = require "gumbo.serialize.util"
local Rope = util.Rope
local verbose = os.getenv "VERBOSE"

local results = {
    pass = 0,
    fail = 0,
    parsed = 0,
    not_parsed = 0
}

local function parse_testdata(filename)
    local n = 0
    local field = "null"
    local buffer = Rope()
    local tests = {}
    for line in io.lines(filename) do
        if line == "#data" or line == "#errors" or line == "#document" then
            tests[n] = tests[n] or {}
            tests[n][field] = buffer:concat("\n")
            buffer = Rope()
            field = line:sub(2, -1)
            if line == "#data" then n = n + 1 end
        else
            buffer:append(line)
        end
    end
    tests[n][field] = buffer:concat("\n") .. "\n"
    return tests
end

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
                printf("Test #%d in %s failed:\n\n", i, filename)
                printf("Input:\n%s\n\n", test.data)
                printf("Expected:\n%s\n", test.document)
                printf("Got:\n%s\n", serialized)
                printf("%s\n\n", string.rep("=", 76))
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
    local tests = parse_testdata(filename)
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

os.exit(results.not_parsed == 0 and results.fail == 0)
