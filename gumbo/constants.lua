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

local booleanAttributes = {
    [""] = Set{"hidden", "irrelevant"},
    audio = Set{"autoplay", "controls"},
    button = Set{"disabled", "autofocus"},
    command = Set{"hidden", "disabled", "checked", "default"},
    datagrid = Set{"multiple", "disabled"},
    details = Set{"open"},
    fieldset = Set{"disabled", "readonly"},
    hr = Set{"noshade"},
    img = Set{"ismap"},
    input = Set[[disabled readonly required autofocus checked ismap]],
    menu = Set{"autosubmit"},
    optgroup = Set{"disabled", "readonly"},
    option = Set{"disabled", "readonly", "selected"},
    output = Set{"disabled", "readonly"},
    script = Set{"defer", "async"},
    select = Set{"disabled", "readonly", "autofocus", "multiple"},
    style = Set{"scoped"},
    video = Set{"autoplay", "controls"},
}

return {
    namespaces = namespaces,
    rcdataElements = rcdataElements,
    voidElements = voidElements,
    booleanAttributes = booleanAttributes
}
