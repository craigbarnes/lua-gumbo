-- Manually converted to Lua from:
-- https://github.com/w3c/web-platform-tests/blob/ee229200b703cf394ed101017ab04912c53bc61a/html/syntax/serializing-html-fragments/outerHTML.html

local gumbo = require "gumbo"
local assert, ipairs = assert, ipairs
local _ENV = nil

local input = [[
<!DOCTYPE html>
<html>
  <head>
    <title>HTML Test: element.outerHTML to verify HTML fragment serialization algorithm</title>
    <link rel="author" title="Intel" href="http://www.intel.com/">
    <link rel="help" href="https://html.spec.whatwg.org/multipage/#html-fragment-serialization-algorithm">
    <link rel="help" href="https://dvcs.w3.org/hg/innerhtml/raw-file/tip/index.html#widl-Element-outerHTML">
  </head>
  <body>
    <div id="log"></div>
  </body>
</html>
]]

local elements = {
    "a", "abbr", "address", "article", "aside", "audio", "b", "bdi",
    "bdo", "blockquote", "body", "button", "canvas", "caption", "cite",
    "code", "colgroup", "command", "datalist", "dd", "del", "details",
    "dfn", "dialog", "div", "dl", "dt", "em", "fieldset", "figcaption",
    "figure", "footer", "form", "h1", "h2", "h3", "h4", "h5", "h6",
    "head", "header", "hgroup", "html", "i", "iframe", "ins", "kbd",
    "label", "legend", "li", "map", "mark", "menu", "meter", "nav",
    "noscript", "object", "ol", "optgroup", "option", "output", "p",
    "pre", "progress", "q", "rp", "rt", "ruby", "s", "samp", "script",
    "section", "select", "small", "span", "strong", "style", "sub",
    "summary", "sup", "table", "tbody", "td", "textarea", "tfoot", "th",
    "thead", "time", "title", "tr", "u", "ul", "var", "video", "data",
}

local noEndTag = {
    "area", "base", "br", "col", "embed", "hr", "img", "input",
    "keygen", "link", "meta", "param", "source", "track", "wbr"
}

local document = assert(gumbo.parse(input))

for i, element in ipairs(elements) do
    local e = document:createElement(element)
    assert(e.outerHTML == "<" .. element .. "></" .. element .. ">")
end

for i, element in ipairs(noEndTag) do
    local e = document:createElement(element)
    assert(e.outerHTML == "<" .. element .. ">")
end
