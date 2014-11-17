local write, ipairs, loadfile = io.write, ipairs, loadfile
local pcall, exit = pcall, os.exit
local yield, wrap = coroutine.yield, coroutine.wrap
local _ENV = nil
local colorize = function(text, color) return color .. text .. "\27[0m" end
local green = function(s) return colorize(s, "\27[32m") end
local boldred = function(s) return colorize(s, "\27[1;31m") end
local bold = function(s) return colorize(s, "\27[1m") end
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
    "test/tree-construction.lua",
}

local function run(tests)
    local function iterate()
        for i, filename in ipairs(tests) do
            local loaded, load_error = loadfile(filename, "t")
            if loaded then
                local ok, run_error = pcall(loaded)
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

write("\n")

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
