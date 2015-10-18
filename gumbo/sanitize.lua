local gumbo = require "gumbo"
local Set = require "gumbo.Set"
local assert = assert
local urlPrefix = (_VERSION == "Lua 5.1") and "^[%z\1-\32]*" or "^[\0-\32]*"
local _ENV = nil

local urlSchemePattern = urlPrefix .. "([a-zA-Z][a-zA-Z0-9+.-]*:)"
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
    local name, value = assert(attr.name), assert(attr.value)
    return
        allowedAttributes[name]
        or (name:find("^data[-].+") ~= nil)
        or (tag == "div" and allowedDivAttributes[name])
        or (tag == "a" and name == "href" and isAllowedHref(value))
        or (tag == "area" and name == "href" and isAllowedHref(value))
        or (tag == "img" and name == "src" and isAllowedImgSrc(value))
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

return sanitize
