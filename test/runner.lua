-- Test runner for the html5lib tree-construction test suite.
-- Don't run directly, use `make check-html5lib` in the top-level directory.

assert(arg[1], "No test files specified")
local gumbo = require "gumbo"
local Buffer = require "gumbo.Buffer"
local Indent = require "gumbo.serialize.Indent"
local open, write, assert, tostring = io.open, io.write, assert, tostring
local format, clock, sort, exit = string.format, os.clock, table.sort, os.exit
local arg = {...}
local verbose = os.getenv "VERBOSE"
local quiet = os.getenv "QUIET"
local hrule = string.rep("=", 76)
local _ENV = nil
local total_passed, total_failed, total_skipped = 0, 0, 0
local start = clock()

local nsmap = {
    ["http://www.w3.org/1999/xhtml"] = "",
    ["http://www.w3.org/1998/Math/MathML"] = "math ",
    ["http://www.w3.org/2000/svg"] = "svg "
}

local function serialize(document)
    assert(document and document.type == "document")
    local buf = Buffer()
    local indent = Indent(2)
    local function write_node(node, depth)
        if node.type == "element" then
            local i1, i2 = indent[depth], indent[depth+1]
            local namespace = nsmap[node.namespaceURI] or ""
            buf:write("| ", i1, "<", namespace, node.localName, ">\n")

            -- The html5lib tree format expects attributes to be sorted by
            -- name, in lexicographic order. Instead of sorting in-place or
            -- copying the entire table, we build a lightweight, sorted index.
            local attr = node.attributes
            local attr_length = #attr
            local attr_index = {}
            for i = 1, attr_length do
                attr_index[i] = i
            end
            sort(attr_index, function(a, b)
                return attr[a].name < attr[b].name
            end)
            for i = 1, attr_length do
                local a = attr[attr_index[i]]
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
                    write_node(children[i], depth + 1)
                end
            end
        elseif node.type == "text" or node.type == "whitespace" then
            buf:write("| ", indent[depth], '"', node.data, '"\n')
        elseif node.type == "comment" then
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
        write_node(childNodes[i], 0)
    end
    return tostring(buf)
end

local function parse_testdata(filename)
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
            tests[testnum][field] = tostring(buffer):sub(1, -2)
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
    tests[testnum][field] = tostring(buffer)
    if testnum > 0 then
        return tests
    else
        return nil, "No test data found in " .. filename
    end
end

for i = 1, #arg do
    local filename = arg[i]
    local tests = assert(parse_testdata(filename))
    local passed, failed, skipped = 0, 0, 0
    for i = 1, #tests do
        local test = tests[i]
        if
            -- Gumbo can't parse document fragments yet
            test["document-fragment"]
            -- See line 134 of python/gumbo/html5lib_adapter_test.py
            or test.data:find("<noscript>", 1, true)
            or test.data:find("<command>", 1, true)
        then
            skipped = skipped + 1
        else
            local document = assert(gumbo.parse(test.data))
            local serialized = assert(serialize(document))
            if serialized == test.document then
                passed = passed + 1
            else
                failed = failed + 1
                if verbose then
                    write(
                        hrule, "\n",
                        filename, ":", test.line, ": Test ", i, " failed\n",
                        hrule, "\n\n",
                        "Input:\n", test.data, "\n\n",
                        "Expected:\n", test.document, "\n",
                        "Received:\n", serialized, "\n"
                    )
                end
            end
        end
    end
    total_passed = total_passed + passed
    total_failed = total_failed + failed
    total_skipped = total_skipped + skipped
end

if not quiet or total_failed > 0 then
    write(
        "\nRan ", total_passed + total_failed + total_skipped, " tests in ",
        format("%.2fs", clock() - start), "\n\n",
        "Passed: ", total_passed, "\n",
        "Failed: ", total_failed, "\n",
        "Skipped: ", total_skipped, "\n\n"
    )
end

if total_failed > 0 then
    if not verbose then
        write "Re-run with VERBOSE=1 for a full report\n"
    end
    exit(1)
end
