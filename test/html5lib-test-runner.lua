#!/usr/bin/lua
assert(arg[1], "No test files specified")
local gumbo = require "gumbo"
local serialize = require "gumbo.serialize.html5lib"
local util = require "gumbo.serialize.util"
local Buffer = util.Buffer
local verbose = os.getenv "VERBOSE"
local results = {pass = 0, fail = 0, skip = 0, n = 0}
local start = os.clock()

local function printf(...)
    io.stdout:write(string.format(...))
end

local function parse_testdata(filename)
    local tests = {[0] = {}, n = 0}
    local buffer = Buffer()
    local field = false
    local linenumber = 0
    for line in io.lines(filename) do
        linenumber = linenumber + 1
        local section = line:match("^#(.*)$")
        if section then
            tests[tests.n][field] = buffer:concat("\n")
            buffer = Buffer()
            field = section
            if section == "data" then
                tests.n = tests.n + 1
                tests[tests.n] = {line = linenumber}
            end
        else
            buffer:append(line)
        end
    end
    tests[tests.n][field] = buffer:concat("\n") .. "\n"
    if tests.n > 0 then
        return tests
    else
        return nil, "No test data found in " .. filename
    end
end

for i = 1, #arg do
    local filename = arg[i]
    local tests = assert(parse_testdata(filename))
    local result = {
        filename = filename,
        basename = filename:gsub("(.*/)(.*)", "%2"),
        pass = 0,
        fail = 0
    }
    for i = 1, tests.n do
        local test = tests[i]
        if test["document-fragment"] then
            -- TODO: handle fragment tests
            results.skip = results.skip + 1
        else
            local document = assert(gumbo.parse(test.data))
            local serialized = serialize(document)
            if serialized == test.document then
                result.pass = result.pass + 1
            else
                result.fail = result.fail + 1
                if verbose then
                    printf("%s\n", string.rep("=", 76))
                    printf("%s:%d: Test %d failed\n", filename, test.line, i)
                    printf("%s\n\n", string.rep("=", 76))
                    printf("Input:\n%s\n\n", test.data)
                    printf("Expected:\n%s\n", test.document)
                    printf("Received:\n%s\n", serialized)
                end
            end
        end
    end
    results.n = results.n + 1
    results[results.n] = result
    results.pass = results.pass + result.pass
    results.fail = results.fail + result.fail
end

for i = 1, results.n do
    local r = results[i]
    printf("%s: %d passed, %d failed\n", r.basename, r.pass, r.fail)
end

local total = results.pass + results.fail + results.skip
printf("\nRan %d tests in %.2fs\n\n", total, os.clock() - start)
printf("Passed: %d\nFailed: %d\n", results.pass, results.fail)
printf("Skipped: %d\n\n", results.skip)
os.exit(results.fail == 0)
