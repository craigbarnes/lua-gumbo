local _parse = require "gumbo.parse"
local type, open, iotype, error = type, io.open, io.type, error
local pairs, assert = pairs, assert

local defaultMetatables = {
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

local _ENV = nil

local function unpackMetatables(mt)
    return
        mt.text,
        mt.comment,
        mt.element,
        mt.attribute,
        mt.document,
        mt.documentType,
        mt.documentFragment,
        mt.nodeList,
        mt.attributeList
end

local function checkMetatables(mt)
    if mt == nil then
        return unpackMetatables(defaultMetatables)
    elseif type(mt) ~= "table" then
        local s = "Error: 'options.metatables' must be a table or nil (got %s)"
        error(s:format(type(mt)), 4)
    end
    for k in pairs(defaultMetatables) do
        local valtype = type(mt[k])
        if valtype ~= "table" then
            local s = "Error: 'options.metatables.%s' must be a table (got %s)"
            error(s:format(k, valtype), 4)
        end
    end
    return unpackMetatables(mt)
end

local function checkArgs(arg2, ctx, ctxns)
    if type(arg2) == "table" then
        -- Use new table-of-options API
        local options = arg2
        return
            options.tabStop,
            options.contextElement,
            options.contextNamespace,
            checkMetatables(options.metatables)
    else
        -- Fall back to old API for backwards compat
        return arg2, ctx, ctxns, unpackMetatables(defaultMetatables)
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
        error("Invalid argument #1: not a file handle or filename string", 2)
    end
    local text, readerr = file:read("*a")
    if closeAfterRead == true then
        file:close()
    end
    if text then
        return _parse(text, checkArgs(arg2, ctx, ctxns))
    else
        return nil, readerr
    end
end

return {
    VERSION = "0.5",
    parse = parse,
    parseFile = parseFile,
    parse_file = parseFile -- Alias for backwards compatibility
}
