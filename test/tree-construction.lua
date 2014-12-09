-- Test runner for the html5lib tree-construction test suite.
-- Runs quiet by default to avoid clobbering test runner output.
-- Run with VERBOSE=1 in the environment for full output.

local gumbo = require "gumbo"
local Buffer = require "gumbo.Buffer"
local Indent = require "gumbo.serialize.Indent"
local parse = gumbo.parse
local ipairs, assert, sort = ipairs, assert, table.sort
local open, popen, write = io.open, io.popen, io.write
local clock, exit = os.clock, os.exit
local verbose = os.getenv "VERBOSE"
local _ENV = nil
local ELEMENT_NODE, TEXT_NODE, COMMENT_NODE = 1, 3, 8
local filenames = {}

local function serialize(document)
    assert(document and document.type == "document")
    local buf = Buffer()
    local indent = Indent(2)
    local function writeNode(node, depth)
        local type = node.nodeType
        if type == ELEMENT_NODE then
            local i1, i2 = indent[depth], indent[depth+1]
            buf:write("| ", i1, "<")
            local namespace = node.namespace
            if namespace ~= "html" then
                buf:write(namespace, " ")
            end
            buf:write(node.localName, ">\n")

            -- The html5lib tree format expects attributes to be sorted by
            -- name, in lexicographic order. Instead of sorting in-place or
            -- copying the entire table, we build a lightweight, sorted index.
            local attr = node.attributes
            local attrLength = #attr
            local attrIndex = {}
            for i = 1, attrLength do
                attrIndex[i] = i
            end
            sort(attrIndex, function(a, b)
                return attr[a].name < attr[b].name
            end)
            for i = 1, attrLength do
                local a = attr[attrIndex[i]]
                local prefix = a.prefix and (a.prefix .. " ") or ""
                buf:write("| ", i2, prefix, a.name, '="', a.value, '"\n')
            end

            local children = node.childNodes
            local n = #children
            for i = 1, n do
                if children[i].type == "text" and children[i+1]
                   and children[i+1].type == "text"
                then
                    -- Merge adjacent text nodes, as expected by the
                    -- spec and the html5lib tests
                    -- TODO: Why doesn't Gumbo do this during parsing?
                    local text = children[i+1].data
                    children[i+1] = children[i]
                    children[i+1].data = children[i+1].data .. text
                else
                    writeNode(children[i], depth + 1)
                end
            end
        elseif type == TEXT_NODE then
            buf:write("| ", indent[depth], '"', node.data, '"\n')
        elseif type == COMMENT_NODE then
            buf:write("| ", indent[depth], "<!-- ", node.data, " -->\n")
        end
    end
    local doctype = document.doctype
    if doctype then
        buf:write("| <!DOCTYPE ", doctype.name)
        local publicId, systemId = doctype.publicId, doctype.systemId
        if publicId ~= "" or systemId ~= "" then
            buf:write(' "', publicId, '" "', systemId, '"')
        end
        buf:write(">\n")
    end
    local childNodes = document.childNodes
    for i = 1, #childNodes do
        writeNode(childNodes[i], 0)
    end
    return buf:tostring()
end

local function parseTestData(filename)
    local file = assert(open(filename, "rb"))
    local text = assert(file:read("*a"))
    file:close()
    local tests = {[0] = {}}
    local buffer = Buffer()
    local field = false
    local testnum, linenum = 0, 0
    for line in text:gmatch "([^\n]*)\n" do
        linenum = linenum + 1
        if line:sub(1, 1) == "#" then
            tests[testnum][field] = buffer:tostring():sub(1, -2)
            buffer = Buffer()
            field = line:sub(2, -1)
            if field == "data" then
                testnum = testnum + 1
                tests[testnum] = {line = linenum}
            end
        else
            buffer:write(line, "\n")
        end
    end
    tests[testnum][field] = buffer:tostring()
    if testnum > 0 then
        return tests
    else
        return nil, "No test data found in " .. filename
    end
end

do
    local pipe = assert(popen("echo test/tree-construction/*.dat"))
    local text = assert(pipe:read("*a"))
    pipe:close()
    assert(text:len() > 0, "No test data found")
    local i = 0
    for filename in text:gmatch("%S+") do
        i = i + 1
        filenames[i] = filename
    end
    assert(i > 0, "No test data found")
end

do
    local hrule = ("="):rep(76)
    local totalPassed, totalFailed, totalSkipped = 0, 0, 0
    local start = clock()
    for _, filename in ipairs(filenames) do
        local tests = assert(parseTestData(filename))
        local passed, failed, skipped = 0, 0, 0
        for i, test in ipairs(tests) do
            local input = assert(test.data)
            if
                -- Gumbo can't parse document fragments yet
                test["document-fragment"]
                -- See line 134 of python/gumbo/html5lib_adapter_test.py
                or input:find("<noscript>", 1, true)
                or input:find("<command>", 1, true)
            then
                skipped = skipped + 1
            else
                local expected = assert(test.document)
                local parsed = assert(parse(input))
                local serialized = assert(serialize(parsed))
                if serialized == expected then
                    passed = passed + 1
                else
                    failed = failed + 1
                    if verbose then
                        write (
                            hrule, "\n",
                            filename, ":", test.line,
                            ": Test ", i, " failed\n",
                            hrule, "\n\n",
                            "Input:\n", input, "\n\n",
                            "Expected:\n", expected, "\n",
                            "Received:\n", serialized, "\n"
                        )
                    end
                end
            end
        end
        totalPassed = totalPassed + passed
        totalFailed = totalFailed + failed
        totalSkipped = totalSkipped + skipped
    end
    local stop = clock()
    if verbose or totalFailed > 0 then
        write (
            "\nRan ", totalPassed + totalFailed + totalSkipped, " tests in ",
            ("%.2fs"):format(stop - start), "\n\n",
            "Passed: ", totalPassed, "\n",
            "Failed: ", totalFailed, "\n",
            "Skipped: ", totalSkipped, "\n\n"
        )
    end
    if totalFailed > 0 then
        if not verbose then
            write "Re-run with VERBOSE=1 for a full report\n"
        end
        exit(1)
    end
end
