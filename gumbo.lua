local _parse = require "gumbo.parse"
local type, open, iotype, error = type, io.open, io.type, error
local assert = assert

local defaultOptions = {
    tabStop = 8,
    contextElement = nil,
    contextNamespace = "html",
    metatables = {
        text = require "gumbo.dom.Text",
        comment = require "gumbo.dom.Comment",
        element = require "gumbo.dom.Element",
        attribute = require "gumbo.dom.Attribute",
        document = require "gumbo.dom.Document",
        documentType = require "gumbo.dom.DocumentType",
        documentFragment = require "gumbo.dom.DocumentFragment",
        nodeList = require "gumbo.dom.NodeList",
        attributeList = require "gumbo.dom.AttributeList"
    }
}

local _ENV = nil

-- TODO: Check validity of fields
local function checkMetatables(mt)
    return
        assert(mt.text),
        assert(mt.comment),
        assert(mt.element),
        assert(mt.attribute),
        assert(mt.document),
        assert(mt.documentType),
        assert(mt.documentFragment),
        assert(mt.nodeList),
        assert(mt.attributeList)
end

-- TODO: Full argument checking
local function checkArgs(arg2, ctx, ctxns)
    if type(arg2) == "table" then
        local options = arg2
        return
            options.tabStop,
            options.contextElement,
            options.contextNamespace,
            checkMetatables(options.metatables or defaultOptions.metatables)
    else
        return arg2, ctx, ctxns, checkMetatables(defaultOptions.metatables)
    end
end

local function parse(text, arg2, ctx, ctxns)
    return _parse(text, checkArgs(arg2, ctx, ctxns))
end

local function parseFile(pathOrFile, arg2, ctx, ctxns)
    local file, openerr
    local closeAfterRead = false
    if type(pathOrFile) == "string" then
        file, openerr = open(pathOrFile)
        if not file then
            return nil, openerr
        end
        closeAfterRead = true
    elseif iotype(pathOrFile) == "file" then
        file = pathOrFile
    else
        error("Invalid argument #1: not a file handle or filename string")
    end
    local text, readerr = file:read("*a")
    if closeAfterRead == true then
        file:close()
    end
    if text then
        return parse(text, arg2, ctx, ctxns)
    else
        return nil, readerr
    end
end

return {
    parse = parse,
    parseFile = parseFile,
    parse_file = parseFile -- Alias for backwards compatibility
}
