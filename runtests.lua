local write, ipairs, loadfile = io.write, ipairs, loadfile
local xpcall, assert, tonumber = xpcall, assert, tonumber
local open, exit, debuginfo = io.open, os.exit, debug.getinfo
local yield, wrap = coroutine.yield, coroutine.wrap
local _ENV = nil
-- TODO: if not isatty(stdout) then colorize = function(s) return s end
local function colorize(s, c) return "\27[" .. c .. "m" .. s .. "\27[0m" end
local function green(s) return colorize(s, "32") end
local function yellow(s) return colorize(s, "33") end
local function boldred(s) return colorize(s, "1;31") end
local function bold(s) return colorize(s, "1") end

local tests = {
    "test/dom/interfaces.lua",
    "test/dom/HTMLCollection-empty-name.lua",
    "test/dom/getElementsByClassName-01.lua",
    "test/dom/getElementsByClassName-02.lua",
    "test/dom/Element-childElementCount.lua",
    "test/dom/Comment-constructor.lua",
    "test/dom/Node-appendChild.lua",
    "test/dom/Node-insertBefore.lua",
    "test/misc.lua",
    "test/tostring.lua",
    "test/tree-construction.lua",
}

local function handler(err)
    local filename, linenumber = err:match("^(.*):([0-9]+): ")
    if not filename then return err end
    linenumber = assert(tonumber(linenumber))
    local level, info = 2
    while true do
        level = level + 1
        info = debuginfo(level, "Sl")
        if not info then return err end
        if info.short_src == filename and info.currentline == linenumber then
            break
        end
    end
    local file = open(filename)
    if not file then return err end
    local line
    for i = 1, linenumber do
        line = file:read()
        if not line then return err end
    end
    line = line:match("^%s*(.-)%s*$")
    return err .. "\n   --->  " .. yellow(line)
end

local function run(tests)
    local function iterate()
        for i, filename in ipairs(tests) do
            local loaded, load_error = loadfile(filename, "t")
            if loaded then
                local ok, run_error = xpcall(loaded, handler)
                if ok then
                    yield(true, filename)
                else
                    yield(false, filename, run_error)
                end
            else
                yield(false, filename, load_error)
            end
        end
    end
    return wrap(function() iterate() end)
end

local function main()
    local passed, failed = 0, 0
    write "\n"
    for ok, filename, err in run(tests) do
        if ok then
            passed = passed + 1
            write(" ", green "PASSED", "  ", filename, "\n")
        else
            failed = failed + 1
            write(" ", boldred "FAILED", "  ", err, "\n")
        end
    end
    write("\n ", bold "Passed:", " ", passed, "\n")
    if failed > 0 then
        write(" ", bold "Failed:", " ", boldred(failed), "\n\n")
        exit(1)
    else
        write "\n"
    end
end

main()
