local open, write, ipairs, loadfile = io.open, io.write, ipairs, loadfile
local type, xpcall, tonumber, exit = type, xpcall, tonumber, os.exit
local yield, wrap = coroutine.yield, coroutine.wrap
local traceback = debug.traceback
local _ENV = nil

local tests = {
    "test/dom/interfaces.lua",
    "test/dom/ElementList.lua",
    "test/dom/getElementsByTagName.lua",
    "test/dom/getElementsByClassName.lua",
    "test/dom/Document-title.lua",
    "test/dom/Document-links.lua",
    "test/dom/Document-serialize.lua",
    "test/dom/DocumentType.lua",
    "test/dom/Element-classList.lua",
    "test/dom/Element-getElementsByClassName.lua",
    "test/dom/Element-remove.lua",
    "test/dom/Element-childElementCount.lua",
    "test/dom/Element-namespaceURI.lua",
    "test/dom/Attribute.lua",
    "test/dom/Comment-constructor.lua",
    "test/dom/Node-appendChild.lua",
    "test/dom/Node-insertBefore.lua",
    "test/dom/Node-constants.lua",
    "test/dom/Node-textContent.lua",
    "test/dom/Node-isEqualNode.lua",
    "test/dom/outerHTML.lua",
    "test/Set.lua",
    "test/misc.lua",
    "test/tostring.lua",
    "test/tree-construction.lua",
    "test/sanitize.lua",
    "test/selector.lua",
}

local function getline(filename, linenumber)
    local file = open(filename)
    if not file then
        return nil
    end
    for i = 1, linenumber - 1 do
        file:read()
    end
    local line = file:read()
    file:close()
    return line
end

local function handler(err)
    if type(err) ~= "string" then return traceback("Unknown error") end
    local filename, linenumber = err:match("^(.*):([0-9]+): ")
    if not filename then return traceback(err) end
    local line = getline(filename, tonumber(linenumber))
    if not line then return traceback(err) end
    local s = "%s\n   --->  \27[33m%s\27[0m\n     %s"
    return s:format(err, line:match("^%s*(.-)%s*$"), traceback())
end

local function runTests()
    local function iterate()
        for i, filename in ipairs(tests) do
            local loaded, loadError = loadfile(filename, "t")
            if loaded then
                local ok, runError = xpcall(loaded, handler)
                if ok then
                    yield(true, filename)
                else
                    yield(false, filename, runError)
                end
            else
                yield(false, filename, loadError)
            end
        end
    end
    return wrap(function() iterate() end)
end

local termfmt = function(s, c) return ("\27[%sm%s\27[0m"):format(c, s) end
local green = function(s) return termfmt(s, "32") end
local boldred = function(s) return termfmt(s, "1;31") end
local bold = function(s) return termfmt(s, "1") end

do
    local passed, failed = 0, 0
    write "\n"
    for ok, filename, err in runTests() do
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
