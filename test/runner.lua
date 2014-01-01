#!/usr/bin/lua
assert(arg[1], "No test files specified")
local gumbo = require "gumbo"
local serialize = require "gumbo.serialize.html5lib"
local util = require "gumbo.serialize.util"
local Buffer = util.Buffer
local verbose = os.getenv "VERBOSE"
local results = {passed = 0, failed = 0, skipped = 0, n = 0}
local start = os.clock()

local function printf(...)
    io.stdout:write(string.format(...))
end

local function parse_testdata(filename)
    local file = assert(io.open(filename))
    local text = assert(file:read("*a"))
    file:close()
    local tests = {[0] = {}, n = 0}
    local buffer = Buffer()
    local field = false
    local linenumber = 0
    for line in text:gmatch "([^\n]*)\n" do
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
        passed = 0,
        failed = 0,
        skipped = 0,
        total = tests.n
    }
    for i = 1, tests.n do
        local test = tests[i]
        if test["document-fragment"] then
            -- TODO: handle fragment tests
            result.skipped = result.skipped + 1
        else
            local document = assert(gumbo.parse(test.data))
            local serialized = serialize(document)
            if serialized == test.document then
                result.passed = result.passed + 1
            else
                result.failed = result.failed + 1
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
    results.passed = results.passed + result.passed
    results.failed = results.failed + result.failed
    results.skipped = results.skipped + result.skipped
end

for i = 1, results.n do
    local r = results[i]
    if r.failed > 0 and r.skipped > 0 then
        local fmt = "%s: %d of %d tests failed, %d of %d tests skipped\n"
        printf(fmt, r.basename, r.failed, r.total, r.skipped, r.total)
    elseif r.failed > 0 then
        printf("%s: %d of %d tests failed\n", r.basename, r.failed, r.total)
    elseif r.skipped > 0 then
        printf("%s: %d of %d tests skipped\n", r.basename, r.skipped, r.total)
    end
end

local total = results.passed + results.failed + results.skipped
printf("\nRan %d tests in %.2fs\n\n", total, os.clock() - start)
printf("Passed: %d\nFailed: %d\n", results.passed, results.failed)
printf("Skipped: %d\n\n", results.skipped)
os.exit(results.failed == 0 and 0 or 1)
