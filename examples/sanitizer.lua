-- This example implements the HTML sanitization rules used by GitHub
-- https://github.com/github/markup#html-sanitization

local gumbo = require "gumbo"
local Set = require "gumbo.Set"
local input = arg[1] or io.stdin
local ipairs, write, assert = ipairs, io.write, assert
local _ENV = nil

local allowedElements = Set {
    "a", "b", "blockquote", "br", "code", "dd", "del", "div", "dl",
    "dt", "em", "h1", "h2", "h3", "h4", "h5", "h6", "h7", "h8", "hr",
    "i", "img", "ins", "kbd", "li", "ol", "p", "pre", "q", "rp", "rt",
    "ruby", "s", "samp", "strike", "strong", "sub", "sup", "table",
    "tbody", "td", "tfoot", "th", "thead", "tr", "tt", "ul", "var",
}

local allowedAttributes = Set {
    "abbr", "accept", "accept-charset", "accesskey", "action", "align",
    "alt", "axis", "border", "cellpadding", "cellspacing", "char",
    "charoff", "charset", "checked", "cite", "clear", "cols", "colspan",
    "color", "compact", "coords", "datetime", "dir", "disabled",
    "enctype", "for", "frame", "headers", "height", "hreflang",
    "hspace", "ismap", "label", "lang", "longdesc", "maxlength",
    "media", "method", "multiple", "name", "nohref", "noshade",
    "nowrap", "prompt", "readonly", "rel", "rev", "rows", "rowspan",
    "rules", "scope", "selected", "shape", "size", "span", "start",
    "summary", "tabindex", "target", "title", "type", "usemap",
    "valign", "value", "vspace", "width", "itemprop"
}

local allowedDivAttributes = Set {
    "itemscope", "itemtype"
}

local allowedHrefSchemes = {
    ["http://"] = "allow",
    ["https://"] = "allow",
    ["mailto:"] = "allow"
}

local allowedImgSrcSchemes = {
    ["http://"] = "allow",
    ["https://"] = "allow"
}

-- TODO: Allow relative URLs for a[href] and img[src]
local function isAllowedAttribute(tag, attr)
    local name = assert(attr.name)
    if allowedAttributes[name] then
        return true
    elseif tag == "div" and allowedDivAttributes[name] then
        return true
    else
        local value = assert(attr.value)
        if tag == "a" and name == "href" then
            local s, n = value:gsub("^[a-z]+:/?/?", allowedHrefSchemes)
            return s ~= value
        elseif tag == "img" and name == "src" then
            local s, n = value:gsub("^[a-z]+://", allowedImgSrcSchemes)
            return s ~= value
        end
    end
end

local document = assert(gumbo.parseFile(input))
local body = assert(document.body)

for node in body:reverseWalk() do
    if node.type == "element" then
        local tag = node.localName
        if allowedElements[tag] then
            local attributes = node.attributes
            for i = #attributes, 1, -1 do
                local attr = attributes[i]
                if not isAllowedAttribute(tag, attr) then
                    node:removeAttribute(attr.name)
                end
            end
        else
            node:remove()
        end
    end
end

write(body.outerHTML, "\n")
