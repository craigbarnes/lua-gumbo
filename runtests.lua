local write, format, ipairs = io.write, string.format, ipairs
local loadfile, pcall, exit = loadfile, pcall, os.exit
local _ENV = nil
local boldred, green, bold, reset = "\27[1;31m", "\27[32m", "\27[1m", "\27[0m"
local passed, failed = 0, 0

local tests = {
    "test/dom/interfaces.lua",
    "test/dom/HTMLCollection-empty-name.lua",
    "test/dom/getElementsByClassName-01.lua",
    "test/dom/getElementsByClassName-02.lua",
    "test/dom/Element-childElementCount.lua",
    "test/dom/Comment-constructor.lua",
    "test/misc.lua",
    "test/tostring.lua",
}

local function printf(...)
    write(format(...), "\n")
end

local function pass(filename)
    printf(" %sPASSED%s  %s", green, reset, filename)
end

local function fail(errmsg)
    printf(" %sFAILED%s  %s", boldred, reset, errmsg)
end

write("\n")

for i, filename in ipairs(tests) do
    local loaded, load_error = loadfile(filename, "t")
    if loaded then
        local ok, run_error = pcall(loaded)
        if ok then
            passed = passed + 1
            pass(filename)
        else
            failed = failed + 1
            fail(run_error)
        end
    else
        failed = failed + 1
        fail(load_error)
    end
end

printf("\n %sPassed:%s %d", bold, reset, passed)

if failed > 0 then
    printf(" %sFailed:%s %s%d%s\n", bold, reset, boldred, failed, reset)
    exit(1)
else
    write "\n"
end
