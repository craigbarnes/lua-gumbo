local gumbo = require "gumbo"
local assert, rawequal, getmetatable = assert, rawequal, getmetatable
local _ENV = nil

do
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
end

do
    local pubid = "-//W3C//DTD XHTML 1.1//EN"
    local sysid = "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd"
    local input = ('<!DOCTYPE html PUBLIC "%s" "%s">'):format(pubid, sysid)
    local document = assert(gumbo.parse(input))
    local doctype = assert(document.doctype)
    assert(doctype:isEqualNode(document.childNodes[1]))
    assert(rawequal(doctype, document.childNodes[1]))
    assert(doctype.name == "html")
    assert(doctype.publicId == pubid)
    assert(doctype.systemId == sysid)
    local clone = assert(doctype:cloneNode())
    assert(clone:isEqualNode(doctype))
    assert(not rawequal(clone, doctype))
    assert(not rawequal(clone, document.childNodes[1]))
    assert(clone.name == "html")
    assert(clone.publicId == pubid)
    assert(clone.systemId == sysid)
    assert(getmetatable(clone))
    assert(getmetatable(clone) == getmetatable(doctype))
end
