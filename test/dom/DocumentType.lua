local gumbo = require "gumbo"
local assert = assert
local _ENV = nil

local input = "<!doctype html><p>no-quirks!</p>"
local document = assert(gumbo.parse(input))
local doctype = assert(document.doctype)

assert(document.compatMode == "CSS1Compat")
assert(doctype.nodeType == document.DOCUMENT_TYPE_NODE)
assert(doctype.nodeName == doctype.name)
assert(doctype.name == "html")
assert(doctype.publicId == "")
assert(doctype.systemId == "")

doctype.publicId = nil
assert(doctype.publicId == "")
doctype.systemId = nil
assert(doctype.systemId == "")
