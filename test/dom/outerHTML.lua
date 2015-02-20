local gumbo = require "gumbo"
local assert, ipairs = assert, ipairs
local _ENV = nil

do -- https://github.com/w3c/web-platform-tests/blob/ee229200b703cf394ed101017ab04912c53bc61a/html/syntax/serializing-html-fragments/outerHTML.html
    local input = "<!DOCTYPE html><title>Fragment serialization test</title>"
    local document = assert(gumbo.parse(input))

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

    for i, element in ipairs(elements) do
        local e = document:createElement(element)
        assert(e.outerHTML == "<" .. element .. "></" .. element .. ">")
    end

    for i, element in ipairs(noEndTag) do
        local e = document:createElement(element)
        assert(e.outerHTML == "<" .. element .. ">")
    end
end

do
    local input = [[<script>a = 1 << 4;</script><p class='&"'>a = 1 << 4;</p>]]
    local document = assert(gumbo.parse(input))
    local script = assert(document:getElementsByTagName("script")[1])
    local p = assert(document:getElementsByTagName("p")[1])
    assert(script.innerHTML == "a = 1 << 4;")
    assert(p.innerHTML == "a = 1 &lt;&lt; 4;")
    assert(p.outerHTML == '<p class="&amp;&quot;">a = 1 &lt;&lt; 4;</p>')
end
