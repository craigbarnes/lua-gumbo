-- This example implements the HTML sanitization rules used by GitHub
-- https://github.com/github/markup#html-sanitization

local gumbo = require "gumbo"
local Set = require "gumbo.Set"
local input = arg[1] or io.stdin
local ipairs, write, assert = ipairs, io.write, assert
local _ENV = nil

local element_whitelist = Set {
    "a", "b", "blockquote", "br", "code", "dd", "del", "div", "dl",
    "dt", "em", "h1", "h2", "h3", "h4", "h5", "h6", "h7", "h8", "hr",
    "i", "img", "ins", "kbd", "li", "ol", "p", "pre", "q", "rp", "rt",
    "ruby", "s", "samp", "strike", "strong", "sub", "sup", "table",
    "tbody", "td", "tfoot", "th", "thead", "tr", "tt", "ul", "var",
}

local attribute_whitelist = Set {
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

local div_attribute_whitelist = Set {
    "itemscope", "itemtype"
}

local document = assert(gumbo.parseFile(input))
local body = assert(document.body)

for node in body:reverseWalk() do
    if node.type == "element" then
        local tag = node.localName
        if element_whitelist[tag] then
            local attributes = node.attributes
            for i = #attributes, 1, -1 do
                local attr = attributes[i].name
                if not attribute_whitelist[attr]
                and not (tag == "div" and div_attribute_whitelist[attr])
                -- TODO: Accept only http:, https:, mailto: and relative URLs
                and not (tag == "a" and attr == "href")
                -- TODO: Accept only http:, https: and relative URLs
                and not (tag == "img" and attr == "src")
                then
                    node:removeAttribute(attr)
                end
            end
        else
            node:remove()
        end
    end
end

write(body.outerHTML, "\n")
