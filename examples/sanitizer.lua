-- This example implements the HTML sanitization rules used by GitHub
-- https://github.com/github/markup#html-sanitization

local gumbo = require "gumbo"
local Set = require "gumbo.Set"
local input = arg[1] or io.stdin
local write, assert = io.write, assert
local _ENV = nil

local urlSchemePattern = "^[\0-\32]*([a-zA-Z][a-zA-Z0-9+.-]*:)"
local allowedHrefSchemes = Set{"http:", "https:", "mailto:"}
local allowedImgSrcSchemes = Set{"http:", "https:"}
local allowedDivAttributes = Set{"itemscope", "itemtype"}

local allowedElements = Set [[
    a b blockquote br code dd del div dl dt em h1 h2 h3 h4 h5 h6 hr i
    img ins kbd li ol p pre q rp rt ruby s samp strike strong sub sup
    table tbody td tfoot th thead tr tt ul var
]]

local allowedAttributes = Set [[
    abbr accept accept-charset accesskey action align alt axis border
    cellpadding cellspacing char charoff charset checked cite clear
    color cols colspan compact coords datetime dir disabled enctype for
    frame headers height hreflang hspace ismap itemprop label lang
    longdesc maxlength media method multiple name nohref noshade nowrap
    prompt readonly rel rev rows rowspan rules scope selected shape size
    span start summary tabindex target title type usemap valign value
    vspace width
]]

local function isAllowedHref(url)
    local scheme = url:match(urlSchemePattern)
    return scheme == nil or allowedHrefSchemes[scheme:lower()] == true
end

local function isAllowedImgSrc(url)
    local scheme = url:match(urlSchemePattern)
    return scheme == nil or allowedImgSrcSchemes[scheme:lower()] == true
end

local function isAllowedAttribute(tag, attr)
    local name = assert(attr.name)
    if allowedAttributes[name] then
        return true
    elseif tag == "div" and allowedDivAttributes[name] then
        return true
    else
        local value = assert(attr.value)
        if tag == "a" and name == "href" and isAllowedHref(value) then
            return true
        elseif tag == "area" and name == "href" and isAllowedHref(value) then
            return true
        elseif tag == "img" and name == "src" and isAllowedImgSrc(value) then
            return true
        end
    end
    return false
end

local function sanitize(root)
    for node in root:reverseWalk() do
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
    return root
end

local document = assert(gumbo.parseFile(input))
local body = assert(sanitize(document.body))
write(body.outerHTML, "\n")
