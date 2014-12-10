local Set = require "gumbo.Set"
local _ENV = nil

local namespaces = {
    html = "http://www.w3.org/1999/xhtml",
    math = "http://www.w3.org/1998/Math/MathML",
    svg = "http://www.w3.org/2000/svg"
}

local voidElements = Set {
    "area", "base", "basefont", "bgsound", "br", "col", "embed",
    "frame", "hr", "img", "input", "keygen", "link", "menuitem", "meta",
    "param", "source", "track", "wbr"
}

local rcdataElements = Set {
    "style", "script", "xmp", "iframe", "noembed", "noframes",
    "plaintext"
}

local booleanAttributes = Set {
    "allowfullscreen", "async", "autofocus", "autoplay", "checked",
    "compact", "controls", "declare", "default", "defer", "disabled",
    "formnovalidate", "hidden", "inert", "ismap", "itemscope", "loop",
    "multiple", "multiple", "muted", "nohref", "noresize", "noshade",
    "novalidate", "nowrap", "open", "readonly", "required", "reversed",
    "scoped", "seamless", "selected", "sortable", "truespeed",
    "typemustmatch"
}

return {
    namespaces = namespaces,
    rcdataElements = rcdataElements,
    voidElements = voidElements,
    booleanAttributes = booleanAttributes
}
